import 'package:flutter_test/flutter_test.dart';
import 'package:yoyaku_mate_provider/models/waiting_list.dart';
import 'package:yoyaku_mate_provider/pages/waiting_page/waiting_providers.dart';

/// 冪等キーの再利用判定を検証する。
///
/// サーバーは (store_id, waiting_id) が同じ要求を「同じ登録の再送」とみなして
/// 既存レコードを返す。したがってこの判定を間違えると、次のどちらかが起きる:
///   常に新規    → 通信失敗後の再試行で整理券が2枚出る (修正前の状態)
///   常に再利用  → 別の客を登録したのに前の客のレコードが返る
///
/// どちらも客に直接見える不具合であり、平常時のテストでは踏まれない
void main() {
  Map<String, dynamic> data({
    int partySize = 2,
    String contact = '090-1111-2222',
    String notes = '',
    List<MenuItem>? menuItems,
  }) {
    return {
      'partySize': partySize,
      'contact': contact,
      'notes': notes,
      'menuItems': menuItems,
    };
  }

  group('waitingFingerprint', () {
    test('同じ内容なら同じ指紋になる', () {
      expect(waitingFingerprint(data()), waitingFingerprint(data()));
    });

    test('人数が違えば別の指紋になる', () {
      expect(
        waitingFingerprint(data(partySize: 2)),
        isNot(waitingFingerprint(data(partySize: 3))),
      );
    });

    test('連絡先が違えば別の指紋になる', () {
      // - 店舗では別の客を続けて登録する。ここが同一判定になると、
      //   前の客の登録が実は成功していた場合に次の客が登録されない
      expect(
        waitingFingerprint(data(contact: '090-1111-2222')),
        isNot(waitingFingerprint(data(contact: '090-3333-4444'))),
      );
    });

    test('備考が違えば別の指紋になる', () {
      expect(
        waitingFingerprint(data(notes: '窓際希望')),
        isNot(waitingFingerprint(data(notes: '禁煙席希望'))),
      );
    });

    test('メニューの数量が違えば別の指紋になる', () {
      expect(
        waitingFingerprint(data(menuItems: [MenuItem(menuId: 'm1', name: 'ラーメン', quantity: 1)])),
        isNot(waitingFingerprint(
            data(menuItems: [MenuItem(menuId: 'm1', name: 'ラーメン', quantity: 2)]))),
      );
    });

    test('メニュー未指定と空リストは同じ扱い', () {
      // - ダイアログの実装差でnull/空が入れ替わっても、同じ登録の再試行が
      //   別物と判定されてしまわないようにする
      expect(
        waitingFingerprint(data(menuItems: null)),
        waitingFingerprint(data(menuItems: const [])),
      );
    });
  });

  group('resolveWaitingId', () {
    const pending = '20260918-120000-111-222';
    const fresh = '20260918-130000-333-444';

    test('前回の失敗と同じ内容なら、前回のキーを再利用する', () {
      final fp = waitingFingerprint(data());
      expect(
        resolveWaitingId(
          pendingId: pending,
          pendingFingerprint: fp,
          fingerprint: fp,
          freshId: fresh,
        ),
        pending,
      );
    });

    test('前回の失敗と内容が違えば、新しいキーを使う', () {
      expect(
        resolveWaitingId(
          pendingId: pending,
          pendingFingerprint: waitingFingerprint(data(contact: '090-1111-2222')),
          fingerprint: waitingFingerprint(data(contact: '090-3333-4444')),
          freshId: fresh,
        ),
        fresh,
      );
    });

    test('保留中のキーが無ければ、新しいキーを使う', () {
      final fp = waitingFingerprint(data());
      expect(
        resolveWaitingId(
          pendingId: null,
          pendingFingerprint: null,
          fingerprint: fp,
          freshId: fresh,
        ),
        fresh,
      );
    });

    test('指紋が失われていれば再利用しない', () {
      // - 安全側に倒す。判断材料が無い状態で再利用すると、別の客に
      //   前の客のレコードを返す危険がある
      expect(
        resolveWaitingId(
          pendingId: pending,
          pendingFingerprint: null,
          fingerprint: waitingFingerprint(data()),
          freshId: fresh,
        ),
        fresh,
      );
    });
  });
}
