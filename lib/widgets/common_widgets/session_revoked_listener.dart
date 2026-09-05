import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yoyaku_mate_provider/routes.dart';
import 'package:yoyaku_mate_provider/services/session_service.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/base_dialog.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

/// 他端末でのログインによってセッションが無効化された際に、アプリ全体で1度だけ
/// ログアウト通知を表示するリスナー
/// - 画面ごとに401を処理すると、処理を書き忘れた画面では黙って失敗する。
///   アプリのルートで購読することで、どの画面を開いていても必ず同じ挙動になる
class SessionRevokedListener extends StatefulWidget {
  final Widget child;

  const SessionRevokedListener({super.key, required this.child});

  @override
  State<SessionRevokedListener> createState() => _SessionRevokedListenerState();
}

class _SessionRevokedListenerState extends State<SessionRevokedListener> {
  StreamSubscription<void>? _subscription;

  /// - 複数のリクエストが同時に401を受け取ってもダイアログが重複しないようにする
  bool _isHandling = false;

  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _subscription = SessionService.instance.onRevoked.listen((_) {
      _handleRevoked();
    });

    // - 起動直後、およびログイン状態が復帰した時に端末セッションを確保しておく。
    //   これが無いと、再インストール直後の最初の操作が
    //   (リトライできないファイルアップロード等の場合に) 一度失敗してしまう
    SessionService.instance.ensureEstablished();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        SessionService.instance.ensureEstablished();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleRevoked() async {
    if (_isHandling) return;
    _isHandling = true;

    // - ルートNavigatorのcontextを使う。どの画面が開いていても確実に表示するため
    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null) {
      _isHandling = false;
      return;
    }

    await showDialog<void>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: BaseDialog(
          title: 'ログアウト通知',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '他の端末でログインされたため、ログアウトします。',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: AppColors.textPrimaryLight,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // - ローカルのセッション情報を消してから認証を切る
    //   (サーバー側は既に無効化済みのため、ここでのDELETE通知は不要)
    await SessionService.instance.clear();
    await FirebaseAuth.instance.signOut();

    final currentContext = rootNavigatorKey.currentContext;
    if (currentContext != null && currentContext.mounted) {
      currentContext.go('/login');
    }

    _isHandling = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
