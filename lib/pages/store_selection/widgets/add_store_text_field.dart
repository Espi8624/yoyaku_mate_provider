import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class AddStoreTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;
  final TextInputType type;
  final String? Function(String?)? validator;

  const AddStoreTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isPassword = false,
    this.type = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: type,
        validator: validator,
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
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}
