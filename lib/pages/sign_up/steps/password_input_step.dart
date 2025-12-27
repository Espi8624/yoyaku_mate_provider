import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/sign_up_viewmodel.dart';
import 'package:yoyaku_mate_provider/widgets/common_buttons/action_button.dart';

class PasswordInputStep extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onNext;

  const PasswordInputStep({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onNext,
  });

  @override
  State<PasswordInputStep> createState() => _PasswordInputStepState();
}

class _PasswordInputStepState extends State<PasswordInputStep> {
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
            const Text('パスワード設定',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('ログインに使用するパスワードを設定してください。',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            _buildTextField(
                controller: widget.passwordController,
                label: 'パスワード',
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'パスワードを入力してください。';
                  if (value.length < 6) return '6文字以上で入力してください。';
                  return null;
                }),
            _buildTextField(
                controller: widget.confirmPasswordController,
                label: 'パスワードの確認',
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'パスワードをもう一度入力してください。';
                  if (value != widget.passwordController.text)
                    return 'パスワードが一致しません。';
                  return null;
                }),
            if (errorMessage != null)
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(errorMessage,
                      style: const TextStyle(color: AppColors.error))),
            const SizedBox(height: 40),
            ActionButton(onPressed: _submit, isLoading: isLoading),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          border: const UnderlineInputBorder(),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.accentPrimary, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
