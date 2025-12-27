import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/sign_up_viewmodel.dart';
import 'package:yoyaku_mate_provider/widgets/common_buttons/action_button.dart';

class EmailInputStep extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function() onNext;

  const EmailInputStep({
    super.key,
    required this.controller,
    required this.onNext,
  });

  @override
  State<EmailInputStep> createState() => _EmailInputStepState();
}

class _EmailInputStepState extends State<EmailInputStep> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignUpViewModel>();
    final isLoading = vm.isLoading;
    final errorMessage = vm.errorMessage;

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('メールアドレス認証',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('使用するメールアドレスを入力してください。',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            TextFormField(
              controller: widget.controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                hintText: 'example@email.com',
                border: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.accentPrimary, width: 2)),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            const Text(
              '※メールアドレスの重複をチェックします',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(errorMessage,
                    style: const TextStyle(color: AppColors.error)),
              ),
            const SizedBox(height: 40),
            ActionButton(
              label: '次へ',
              onPressed: _submit,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onNext();
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'メールアドレスを入力してください。';
    }
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return '正しいメールアドレスの形式で入力してください。';
    }
    return null;
  }
}
