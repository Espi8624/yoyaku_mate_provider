import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/base_dialog.dart';

/// BaseDialog を showDialog で開くだけのテスト用アプリ
Widget _testApp({
  bool barrierDismissible = true,
  double? width,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: barrierDismissible,
              builder: (_) => BaseDialog(
                title: 'テストダイアログ',
                width: width,
                content: const Text('本文'),
              ),
            ),
            child: const Text('開く'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('開く'));
  await tester.pumpAndSettle();
  expect(find.text('テストダイアログ'), findsOneWidget);
}

void main() {
  group('BaseDialog のバリア操作', () {
    testWidgets('ダイアログ外側をタップすると閉じる', (tester) async {
      await tester.pumpWidget(_testApp());
      await _openDialog(tester);

      // - カードの外側をタップする。座標は「DialogのinsetPaddingより内側」かつ
      //   「カードより上」の位置を選ぶ。ここはバリアが見えている領域だが、
      //   Dialogの子が画面全体に広がっているとタップが吸収され、
      //   バリアまで届かずダイアログが閉じない
      final cardRect = tester.getRect(find.ancestor(
        of: find.text('テストダイアログ'),
        matching: find.byType(ClipRRect),
      ));
      await tester.tapAt(Offset(cardRect.center.dx, cardRect.top - 60));
      await tester.pumpAndSettle();

      expect(find.text('テストダイアログ'), findsNothing,
          reason: '外側タップでダイアログが閉じていない');
    });

    testWidgets('barrierDismissible: false なら外側タップでは閉じない', (tester) async {
      // - セッション失効通知など、ユーザーに必ず確認させたいダイアログのための挙動。
      //   BaseDialog側の変更でこの制御が壊れないことを固定する
      await tester.pumpWidget(_testApp(barrierDismissible: false));
      await _openDialog(tester);

      final cardRect = tester.getRect(find.ancestor(
        of: find.text('テストダイアログ'),
        matching: find.byType(ClipRRect),
      ));
      await tester.tapAt(Offset(cardRect.center.dx, cardRect.top - 60));
      await tester.pumpAndSettle();

      expect(find.text('テストダイアログ'), findsOneWidget,
          reason: 'barrierDismissible: false なのに閉じてしまった');
    });

    testWidgets('カード内側をタップしても閉じない', (tester) async {
      await tester.pumpWidget(_testApp());
      await _openDialog(tester);

      await tester.tap(find.text('本文'));
      await tester.pumpAndSettle();

      expect(find.text('テストダイアログ'), findsOneWidget,
          reason: '内側タップで閉じてしまった');
    });
  });

  group('BaseDialog のレイアウト', () {
    testWidgets('カードが画面全体を占有していない', (tester) async {
      await tester.pumpWidget(_testApp());
      await _openDialog(tester);

      final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
      final cardSize = tester.getSize(
        find.ancestor(
          of: find.text('テストダイアログ'),
          matching: find.byType(ClipRRect),
        ),
      );

      // - 高さは中身に合わせて縮む (画面いっぱいにならない)
      expect(cardSize.height, lessThan(screenSize.height),
          reason: 'カードが画面の高さいっぱいに広がっている');
    });

    testWidgets('width 指定が反映される', (tester) async {
      await tester.pumpWidget(_testApp(width: 320));
      await _openDialog(tester);

      final cardSize = tester.getSize(
        find.ancestor(
          of: find.text('テストダイアログ'),
          matching: find.byType(ClipRRect),
        ),
      );

      expect(cardSize.width, lessThanOrEqualTo(320));
    });
  });
}
