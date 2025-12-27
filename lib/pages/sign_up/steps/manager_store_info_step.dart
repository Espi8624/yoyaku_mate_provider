import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/sign_up_viewmodel.dart';
import 'package:yoyaku_mate_provider/widgets/common_buttons/action_button.dart';

class ManagerStoreInfoStep extends StatefulWidget {
  final TextEditingController storeNameController;
  final TextEditingController storeAddressController;
  final TextEditingController storePhoneController;
  final VoidCallback onSubmit;

  const ManagerStoreInfoStep({
    super.key,
    required this.storeNameController,
    required this.storeAddressController,
    required this.storePhoneController,
    required this.onSubmit,
  });

  @override
  State<ManagerStoreInfoStep> createState() => _ManagerStoreInfoStepState();
}

class _ManagerStoreInfoStepState extends State<ManagerStoreInfoStep> {
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
            const Text('店舗情報',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('管理する店舗の情報を入力してください。',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            _buildTextField(
                controller: widget.storeNameController,
                label: '店舗名',
                validator: (value) {
                  if (value == null || value.isEmpty) return '店舗名を入力してください。';
                  return null;
                }),
            _buildTextField(
                controller: widget.storeAddressController,
                label: '住所',
                validator: (value) {
                  if (value == null || value.isEmpty) return '住所を入力してください。';
                  return null;
                }),
            _buildTextField(
              controller: widget.storePhoneController,
              label: '電話番号（店舗）',
              type: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) return '店舗電話を入力してください。';
                return _validatePhoneNumber(value);
              },
            ),
            if (errorMessage != null)
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(errorMessage,
                      style: const TextStyle(color: AppColors.error))),
            const SizedBox(height: 40),
            ActionButton(
                label: '登録完了', onPressed: _submit, isLoading: isLoading),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit();
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

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return '電話番号を入力してください。';
    final phoneRegex = RegExp(r'^0\d{9,10}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[-\s]'), ''))) {
      return '正しい電話番号を入力してください。';
    }
    return null;
  }
}
