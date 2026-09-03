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

  const WaitingListData({required this.items, required this.qrToken});
}

@riverpod
class WaitingListNotifier extends _$WaitingListNotifier {
  StreamSubscription<List<WaitingList>>? _subscription;
  // 楽観的更新中はポーリングストリームによる上書きを防止する汎用フラグ
  bool _isPerformingOptimisticUpdate = false;

  @override
  Future<WaitingListData> build({required String storeId}) async {
    ref.onDispose(() => _subscription?.cancel());
    final service = ref.watch(waitingServiceProvider);

    try {
      // 待機リスト取得とQRトークン取得を同時に実行
      final results = await Future.wait([
        service.fetchWaitingCustomers(storeId),
        service.fetchQRToken(storeId),
      ]);

      final items = (results[0] as List<WaitingList>)
        ..sort((a, b) => b.registrationTime.compareTo(a.registrationTime));
      final tokenData = results[1] as Map<String, String>;

      _subscribeToStream(storeId);

      return WaitingListData(items: items, qrToken: tokenData['v_token']);
    } catch (e) {
      // "データなし"は正常系として空リスト扱い (既存 _handleStreamError と同じ判定)
      if (e.toString().contains('data":null')) {
        _subscribeToStream(storeId);
        return const WaitingListData(items: [], qrToken: null);
      }
      rethrow;
    }
  }

  void _subscribeToStream(String storeId) {
    final service = ref.read(waitingServiceProvider);
    service.startPolling(storeId);

    _subscription?.cancel();
    _subscription = service.waitingListStream.listen(
      (updatedList) {
        // 楽観的更新中はポーリングデータによる上書きを防止
        if (_isPerformingOptimisticUpdate) return;

        updatedList.sort((a, b) => b.registrationTime.compareTo(a.registrationTime));
        final currentToken = state.valueOrNull?.qrToken;
        state = AsyncData(WaitingListData(items: updatedList, qrToken: currentToken));
      },
      onError: (e) {
        final currentToken = state.valueOrNull?.qrToken;
        if (e.toString().contains('data":null')) {
          state = AsyncData(WaitingListData(items: const [], qrToken: currentToken));
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
      // 冪等キーとして使用するユニーク待機ID (フォーマット: YYYYMMDD-HHmmss-SSS-Random)
      final clientWaitingId = "$dateStr-$timeStr-$msStr-$randomSuffix";
      // 顧客が登録した実際の時刻 (ISO 8601 形式)
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

      final newItems = [...(current?.items ?? const <WaitingList>[]), newWaitingItem]
        ..sort((a, b) => b.registrationTime.compareTo(a.registrationTime));
      state = AsyncData(WaitingListData(items: newItems, qrToken: current?.qrToken));
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
    state = AsyncData(WaitingListData(items: optimisticItems, qrToken: current.qrToken));

    try {
      final service = ref.read(waitingServiceProvider);
      await service.updateWaitingStatus(
          storeId: storeId, waitingId: waitingId, status: newStatus);
    } catch (e) {
      // 失敗時、UI を以前の状態にロールバック
      final rollbackItems = [...optimisticItems];
      rollbackItems[itemIndex] = originalItem;
      state = AsyncData(WaitingListData(items: rollbackItems, qrToken: current.qrToken));
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
    state = AsyncData(WaitingListData(items: const [], qrToken: current.qrToken));

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
