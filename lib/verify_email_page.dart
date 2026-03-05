import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 認証メールが既に発送されていると仮定し、ステータス確認
    _timer = Timer.periodic(
        const Duration(seconds: 5), (_) => _checkEmailVerified());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload(); // Firebaseで最新ユーザーステータス取得

    if (user.emailVerified) {
      _timer?.cancel();
      if (!context.mounted) return;
      context.go('/');
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        ToastWidget.show(context, '確認メールを再送信しました。', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastWidget.show(context, 'エラー: ${e.toString()}',
            type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('メールアドレス認証'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.mark_email_read_outlined,
                    size: 80, color: AppColors.accentPrimary),
                const SizedBox(height: 32),
                const Text(
                  '認証メールを送信しました。',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '${FirebaseAuth.instance.currentUser?.email} に送信されたメールを確認し、記載されたリンクをクリックしてアカウントの認証を完了してください。',
                  style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  onPressed: _resendVerificationEmail,
                  label: const Text('確認メールを再送信'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary.withOpacity(0.1),
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                  child: const Text('他のアカウントでログイン',
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
