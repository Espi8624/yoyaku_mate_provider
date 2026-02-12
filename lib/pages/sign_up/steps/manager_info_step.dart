import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/widgets/common_buttons/action_button.dart';

class ManagerInfoStep extends StatefulWidget {
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameKanaController;
  final TextEditingController firstNameKanaController;
  final VoidCallback onNext;

  const ManagerInfoStep({
    super.key,
    required this.lastNameController,
    required this.firstNameController,
    required this.lastNameKanaController,
    required this.firstNameKanaController,
    required this.onNext,
  });

  @override
  State<ManagerInfoStep> createState() => _ManagerInfoStepState();
}

class _ManagerInfoStepState extends State<ManagerInfoStep> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('管理者情報',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('本人確認のために情報を入力してください。',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        controller: widget.lastNameController, label: '姓')),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(
                        controller: widget.firstNameController, label: '名')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        controller: widget.lastNameKanaController,
                        label: 'フリガナ（姓）')),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(
                        controller: widget.firstNameKanaController,
                        label: 'フリガナ（名）')),
              ],
            ),
            const SizedBox(height: 40),
            ActionButton(onPressed: _submit),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
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
        validator: (value) {
          if (value == null || value.isEmpty) return '入力してください。';
          return null;
        },
      ),
    );
  }
}
