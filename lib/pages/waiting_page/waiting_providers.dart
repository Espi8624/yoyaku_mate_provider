// 待機リスト画面の状態管理 (Riverpod)
//
// Provider(MVVM)からの移行。他ページから参照されないページローカル状態。
//
// 既存ViewModelの挙動をそのまま踏襲する点:
// - SSEポーリングストリームを購読しつつ、楽観的更新中(_isPerformingOptimisticUpdate)は
//   ストリームからの上書きを無視する
// - 初回fetch時に"data":nullを含むエラーは「データなし」として空リスト扱い
//   (エラー表示しない)
// - addWaitingItem失敗時は全体再取得(既存の loadWaitingList() 呼び出し相当)で
//   サーバーと同期し直す
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yoyaku_mate_provider/models/waiting_list.dart';
import 'package:yoyaku_mate_provider/services/waiting_service.dart';

part 'waiting_providers.g.dart';

@riverpod
WaitingService waitingService(Ref ref) => WaitingService(); // シングルトン

class WaitingListData {
  final List<WaitingList> items;
  final String? qrToken;
  final String? boardKey;

  const WaitingListData({required this.items, required this.qrToken, this.boardKey});
}

/// waitingFingerprint は登録内容から「同じ登録かどうか」を判定するための指紋を作る。
///
/// 冪等キーの再利用を、内容が一致する再試行だけに限定するために使う。
/// 店舗では別の客を続けて登録するのが普通なので、内容を見ずにキーを使い回すと
/// 前の客のレコードが返ってきてしまう ([WaitingListNotifier] のフィールド参照)
String waitingFingerprint(Map<String, dynamic> data) {
  final menuItems = data['menuItems'] as List<MenuItem>?;
  final menuPart = (menuItems ?? const <MenuItem>[])
      .map((e) => '${e.menuId}x${e.quantity}')
      .join(',');
  return [
    data['partySize']?.toString() ?? '',
    data['contact']?.toString() ?? '',
    data['notes']?.toString() ?? '',
    menuPart,
  ].join('|');
}

/// resolveWaitingId は今回の送信に使う冪等キーを決める。
///
/// 前回失敗した送信のキー([pendingId])を再利用するのは、その登録内容が
/// 今回と一致するとき([pendingFingerprint] == [fingerprint])だけ。
/// 一致しなければ新しいキー([freshId])を使う。
///
/// この分岐が要点であり、間違えると次のどちらかが起きる:
///   常に新規 → 通信失敗後の再試行で整理券が2枚出る (修正前の状態)
///   常に再利用 → 別の客を登録したのに前の客のレコードが返る
String resolveWaitingId({
  required String? pendingId,
  required String? pendingFingerprint,
  required String fingerprint,
  required String freshId,
}) {
  if (pendingId != null && pendingFingerprint == fingerprint) {
    return pendingId;
  }
  return freshId;
}

@riverpod
class WaitingListNotifier extends _$WaitingListNotifier {
  StreamSubscription<List<WaitingList>>? _subscription;
  // 楽観的更新中はポーリングストリームによる上書きを防止する汎用フラグ
  bool _isPerformingOptimisticUpdate = false;

  // - dispose後にストリームのコールバックが走るのを止めるためのフラグ。
  //   build()のawait中にinvalidateされると、onDisposeが先に走ったあとで
  //   購読が張られ、二度とcancelされないリークになっていた
  bool _disposed = false;

  // - build()の完了前に届いたSSEデータの退避先。この時点ではまだstateに
  //   書けないため、初期取得の結果より優先して採用する(初期取得より新しいデータのため)
  List<WaitingList>? _pendingItems;
  bool _isBuilt = false;

  // - 送信に失敗した登録の冪等キー(waiting_id)と、その登録内容の指紋。
  //
  //   サーバーは (store_id, waiting_id) が同じ要求を「同じ登録の再送」とみなして
  //   既存レコードを返す。キーを送信のたびに作り直すと、通信失敗のあとにもう一度
  //   登録した際サーバーからは別の登録に見え、整理券が2枚出てしまう。
  //   そのため失敗したキーを保持し、同じ登録をやり直すときに再利用する。
  //
  //   指紋を併せて持つのが要点。キーだけを持ち回すと、客Aの登録に失敗したあと
  //   別の客Bを登録したときに客Aのキーが使われ、「客Aの登録が実は成功していた」
  //   場合に客Bのつもりで客Aのレコードが返ってくる。店舗では別の客を続けて
  //   登録するのが普通なので、これは実際に起きる
  String? _pendingWaitingId;
  String? _pendingWaitingFingerprint;

  @override
  Future<WaitingListData> build({required String storeId}) async {
    ref.onDispose(() {
      _disposed = true;
      _subscription?.cancel();
    });
    final service = ref.watch(waitingServiceProvider);

    // - 購読はawaitより先に張る。以前は初期取得3往復(リスト/board_key/QRトークン)が
    //   終わってから購読していたため、その間に入った更新を丸ごと取りこぼしていた
    _subscribeToStream(storeId);

    try {
      // 待機リスト取得とboard_key取得を同時に実行。QRトークン発行はboard_key検証が
      // 必須になったため、board_keyが揃ってから続けて取得する
      final results = await Future.wait([
        service.fetchWaitingCustomers(storeId),
        service.fetchBoardKey(storeId),
      ]);

      final items = (results[0] as List<WaitingList>)
        ..sort((a, b) => b.registrationTime.compareTo(a.registrationTime));
      final boardKey = results[1] as String;
      final tokenData = await service.fetchQRToken(storeId, boardKey);

      return WaitingListData(
          items: _takePendingItems() ?? items,
          qrToken: tokenData['v_token'],
          boardKey: boardKey);
    } catch (e) {
      // "データなし"は正常系として空リスト扱い (既存 _handleStreamError と同じ判定)
      if (e.toString().contains('data":null')) {
        return WaitingListData(
            items: _takePendingItems() ?? const [], qrToken: null);
      }
      // - 初期取得が失敗してもSSEの購読は生きている。以降に届いた更新で
      //   エラー表示から自動復帰できるよう、反映を止めないでおく
      _isBuilt = true;
      rethrow;
    }
  }

  // build()完了前に届いていたSSEデータを取り出す。以降は通常どおりstateへ反映される
  List<WaitingList>? _takePendingItems() {
    _isBuilt = true;
    final pending = _pendingItems;
    _pendingItems = null;
    return pending;
  }

  void _subscribeToStream(String storeId) {
    final service = ref.read(waitingServiceProvider);
    service.startPolling(storeId);

    _subscription?.cancel();
    _subscription = service.waitingListStream.listen(
      (updatedList) {
        if (_disposed) return;
        // 楽観的更新中はポーリングデータによる上書きを防止
        if (_isPerformingOptimisticUpdate) return;

        updatedList.sort((a, b) => b.registrationTime.compareTo(a.registrationTime));

        // build()完了前はstateに触れられないため退避しておく
        if (!_isBuilt) {
          _pendingItems = updatedList;
          return;
        }

        final currentToken = state.valueOrNull?.qrToken;
        final currentBoardKey = state.valueOrNull?.boardKey;
        state = AsyncData(WaitingListData(
            items: updatedList, qrToken: currentToken, boardKey: currentBoardKey));
      },
      onError: (e) {
        if (_disposed || !_isBuilt) return;
        final currentToken = state.valueOrNull?.qrToken;
        final currentBoardKey = state.valueOrNull?.boardKey;
        if (e.toString().contains('data":null')) {
          state = AsyncData(WaitingListData(
              items: const [], qrToken: currentToken, boardKey: currentBoardKey));
        } else {
          state = AsyncError('データ処理中エラーが発生しました', StackTrace.current);
        }
      },
    );
  }

  // 新規待機追加。呼び出し元(AddWaitingDialogの戻り値)がdataの形を保証する
  Future<void> addWaitingItem(Map<String, dynamic> data) async {
    _isPerformingOptimisticUpdate = true;
    final current = state.valueOrNull;

    try {
      final now = DateTime.now();
      // JST (UTC+9) タイムゾーンに変換
      final jstNow = now.toUtc().add(const Duration(hours: 9));
      final dateStr =
          "${jstNow.year}${jstNow.month.toString().padLeft(2, '0')}${jstNow.day.toString().padLeft(2, '0')}";
      final timeStr =
          "${jstNow.hour.toString().padLeft(2, '0')}${jstNow.minute.toString().padLeft(2, '0')}${jstNow.second.toString().padLeft(2, '0')}";
      final msStr = jstNow.millisecond.toString().padLeft(3, '0');
      // 重複を防ぐためのマイクロ秒ベースのランダムな接尾辞 (100〜999)
      final randomSuffix = (100 + (now.microsecondsSinceEpoch % 900)).toString();

      // - 冪等キーは「登録1件」につき1つ。前回の送信が失敗していて、かつ内容が
      //   同じ登録なら、そのときのキーを再利用する (resolveWaitingId 参照)
      final fingerprint = waitingFingerprint(data);
      final clientWaitingId = resolveWaitingId(
        pendingId: _pendingWaitingId,
        pendingFingerprint: _pendingWaitingFingerprint,
        fingerprint: fingerprint,
        // フォーマット: YYYYMMDD-HHmmss-SSS-Random
        freshId: "$dateStr-$timeStr-$msStr-$randomSuffix",
      );

      // - 送信前に控える。成功したら下で消す。例外で抜けた場合は残るため、
      //   次の同じ内容の登録で再利用される
      _pendingWaitingId = clientWaitingId;
      _pendingWaitingFingerprint = fingerprint;

      // 顧客が登録した実際の時刻 (ISO 8601 形式)
      // - キーとは違い毎回更新する。固定すると、しばらく経ってから再試行した場合に
      //   古い時刻で登録され、待ち順がずれる
      final regTimeStr =
          "${jstNow.year}-${jstNow.month.toString().padLeft(2, '0')}-${jstNow.day.toString().padLeft(2, '0')}T${jstNow.hour.toString().padLeft(2, '0')}:${jstNow.minute.toString().padLeft(2, '0')}:${jstNow.second.toString().padLeft(2, '0')}.$msStr+09:00";

      final service = ref.read(waitingServiceProvider);
      final newWaitingItem = await service.createWaitingListItem(
        storeId: storeId,
        partySize: data['partySize'] as int,
        nationality: 'unknown',
        contact: data['contact']?.toString() ?? '',
        notes: data['notes']?.toString() ?? '',
        menuItems: data['menuItems'] as List<MenuItem>?,
        vToken: current?.qrToken,
        waitingId: clientWaitingId,
        registrationTime: regTimeStr,
      );

      // - 登録が確定したので冪等キーを手放す。次の登録は新しいキーで始める。
      //   ここで消さないと、同じ内容の客を続けて登録したときに2件目が
      //   1件目のレコードとして返り、登録されないまま完了したように見える
      _pendingWaitingId = null;
      _pendingWaitingFingerprint = null;

      final newItems = [...(current?.items ?? const <WaitingList>[]), newWaitingItem]
        ..sort((a, b) => b.registrationTime.compareTo(a.registrationTime));
      state = AsyncData(WaitingListData(
          items: newItems, qrToken: current?.qrToken, boardKey: current?.boardKey));
    } catch (e) {
      // 失敗時はサーバーと確実に同期するため全体再取得 (既存の loadWaitingList() 相当)
      ref.invalidateSelf();
      rethrow;
    } finally {
      _isPerformingOptimisticUpdate = false;
    }
  }

  Future<void> updateWaitingStatus(String waitingId, String newStatus) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final itemIndex = current.items.indexWhere((item) => item.waitingId == waitingId);
    if (itemIndex == -1) return;
    final originalItem = current.items[itemIndex];

    _isPerformingOptimisticUpdate = true;

    // ローカルデータを先に修正し、UI 即アップデート (Optimistic Update)
    final updatedItem = originalItem.copyWith(
      status: newStatus,
      // notified(呼び出し)の場合は calledTime も更新
      calledTime: newStatus == 'notified' ? DateTime.now() : originalItem.calledTime,
      // completed(入店)の場合は entryTime も更新しないと「直前入場時間」が即時反映されない
      entryTime: newStatus == 'completed' ? DateTime.now() : null,
    );
    final optimisticItems = [...current.items];
    optimisticItems[itemIndex] = updatedItem;
    state = AsyncData(WaitingListData(
        items: optimisticItems, qrToken: current.qrToken, boardKey: current.boardKey));

    try {
      final service = ref.read(waitingServiceProvider);
      await service.updateWaitingStatus(
          storeId: storeId, waitingId: waitingId, status: newStatus);
    } catch (e) {
      // 失敗時、UI を以前の状態にロールバック
      final rollbackItems = [...optimisticItems];
      rollbackItems[itemIndex] = originalItem;
      state = AsyncData(WaitingListData(
          items: rollbackItems, qrToken: current.qrToken, boardKey: current.boardKey));
      rethrow;
    } finally {
      _isPerformingOptimisticUpdate = false;
    }
  }

  // 待機目録初期化 (※ 現在のUIには呼び出し箇所がないが、既存ViewModelとのAPI互換性維持のため移植)
  Future<void> clearWaitingList() async {
    final current = state.valueOrNull;
    if (current == null) return;

    _isPerformingOptimisticUpdate = true;
    state = AsyncData(WaitingListData(
        items: const [], qrToken: current.qrToken, boardKey: current.boardKey));

    try {
      final service = ref.read(waitingServiceProvider);
      await service.clearWaitingList(storeId);
    } catch (e) {
      // 失敗時、UI を以前の状態にロールバック
      state = AsyncData(current);
      rethrow;
    } finally {
      _isPerformingOptimisticUpdate = false;
    }
  }
}
