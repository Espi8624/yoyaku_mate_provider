import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/store_selection/widgets/add_store_text_field.dart';
import 'package:yoyaku_mate_provider/pages/store_selection/widgets/add_store_action_button.dart';

class StoreInfoForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String? errorMessage;

  const StoreInfoForm({
    super.key,
    required this.nameController,
    required this.addressController,
    required this.phoneController,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
  });

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return '電話番号を入力してください。';
    }
    final phoneRegex = RegExp(r'^0\d{9,10}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[-\s]'), ''))) {
      return '正しい電話番号を入力してください。';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('店舗情報',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('顧客に表示される店舗情報を入力してください。',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          AddStoreTextField(controller: nameController, label: '店名'),
          AddStoreTextField(controller: addressController, label: '住所'),
          AddStoreTextField(
            controller: phoneController,
            label: '店舗電話番号',
            type: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) return '店舗電話を入力してください。';
              return _validatePhoneNumber(value);
            },
          ),
          if (errorMessage != null)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center)),
          const SizedBox(height: 60),
          AddStoreActionButton(
              label: '登録', onPressed: onSubmit, isLoading: isLoading),
        ],
      ),
    );
  }
}
