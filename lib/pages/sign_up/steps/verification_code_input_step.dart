import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/sign_up_viewmodel.dart';
import 'package:yoyaku_mate_provider/widgets/common_buttons/action_button.dart';

class VerificationCodeInputStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  const VerificationCodeInputStep({
    super.key,
    required this.controller,
    required this.onVerify,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignUpViewModel>();
    final isLoading = vm.isLoading;
    final errorMessage = vm.errorMessage;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('認証コード入力',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('SMSで送信された6桁のコードを入力してください。',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: const InputDecoration(
                labelText: '認証コード',
                hintText: '',
                border: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.accentPrimary, width: 2)),
                counterText: ''),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
                onPressed: isLoading ? null : onResend,
                child: const Text('コードを再送信',
                    style: TextStyle(color: AppColors.accentPrimary))),
          ),
          if (errorMessage != null)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(errorMessage,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center)),
          const SizedBox(height: 40),
          ActionButton(label: '認証', onPressed: onVerify, isLoading: isLoading),
        ],
      ),
    );
  }
}
