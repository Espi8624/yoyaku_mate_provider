import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/sign_up_viewmodel.dart';
import 'package:yoyaku_mate_provider/widgets/common_buttons/action_button.dart';

class PhoneNumberInputStep extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSendCode;

  const PhoneNumberInputStep({
    super.key,
    required this.controller,
    required this.onSendCode,
  });

  @override
  State<PhoneNumberInputStep> createState() => _PhoneNumberInputStepState();
}

class _PhoneNumberInputStepState extends State<PhoneNumberInputStep> {
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
            const Text('電話番号認証',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('本人確認のために電話番号を認証してください。',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            _buildTextField(
                controller: widget.controller,
                label: '電話番号',
                type: TextInputType.phone,
                validator: _validatePhoneNumber),
            const SizedBox(height: 16),
            const Text('※ハイフンなしで入力してください\n※認証コードがSMSで送信されます',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            if (errorMessage != null)
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(errorMessage,
                      style: const TextStyle(color: AppColors.error))),
            const SizedBox(height: 40),
            ActionButton(
                label: '認証コードを送信', onPressed: _submit, isLoading: isLoading),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSendCode();
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.accentPrimary, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return '電話番号を入力してください。';
    }
    // Simple validation: just digits and optional hyphens, length check
    // Logic from original code:
    final clean = value.replaceAll(RegExp(r'[-\s]'), '');
    if (clean.length < 10 || clean.length > 11) {
      return '正しい電話番号を入力してください。';
    }
    return null;
  }
}
