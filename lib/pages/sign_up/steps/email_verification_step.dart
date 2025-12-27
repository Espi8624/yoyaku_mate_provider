import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/sign_up_viewmodel.dart';
import 'package:yoyaku_mate_provider/widgets/common_buttons/action_button.dart';

class EmailVerificationStep extends StatelessWidget {
  final VoidCallback onVerifyComplete;
  final VoidCallback onResend;

  const EmailVerificationStep({
    super.key,
    required this.onVerifyComplete,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignUpViewModel>();
    final isLoading = vm.isLoading;
    final errorMessage = vm.errorMessage;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('メール認証',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('送信されたメールの認証リンクをクリックしてください。',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 48),
          const Icon(Icons.mark_email_read_outlined,
              size: 80, color: AppColors.accentPrimary),
          const SizedBox(height: 32),
          const Text(
            '1. メールボックスを確認\n2. 認証リンクをクリック\n3. アプリに戻って「認証完了」をタップ',
            style: TextStyle(
                fontSize: 15, color: AppColors.textSecondary, height: 1.8),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
              onPressed: isLoading ? null : onResend,
              child: const Text('メールを再送信',
                  style: TextStyle(color: AppColors.accentPrimary))),
          if (errorMessage != null)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(errorMessage,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center)),
          const SizedBox(height: 40),
          ActionButton(
              label: '認証完了', onPressed: onVerifyComplete, isLoading: isLoading),
        ],
      ),
    );
  }
}
