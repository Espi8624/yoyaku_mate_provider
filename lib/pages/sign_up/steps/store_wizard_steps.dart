import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/store_selection/widgets/add_store_text_field.dart';
import 'package:yoyaku_mate_provider/pages/store_selection/widgets/add_store_action_button.dart';

// --- Step 1: Basic Info ---
class StoreBasicInfoStep extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final VoidCallback onNext;

  const StoreBasicInfoStep({
    super.key,
    required this.nameController,
    required this.addressController,
    required this.phoneController,
    required this.onNext,
  });

  @override
  State<StoreBasicInfoStep> createState() => _StoreBasicInfoStepState();
}

class _StoreBasicInfoStepState extends State<StoreBasicInfoStep> {
  final _formKey = GlobalKey<FormState>();

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

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('店舗情報',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('基本情報を入力してください。',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            AddStoreTextField(
              controller: widget.nameController,
              label: '店名',
              validator: (v) => v!.isEmpty ? '店名を入力してください。' : null,
            ),
            AddStoreTextField(
              controller: widget.addressController,
              label: '住所',
              validator: (v) => v!.isEmpty ? '住所を入力してください。' : null,
            ),
            AddStoreTextField(
              controller: widget.phoneController,
              label: '店舗電話番号',
              type: TextInputType.phone,
              validator: _validatePhoneNumber,
            ),
            const SizedBox(height: 40),
            AddStoreActionButton(label: '次へ', onPressed: _handleNext),
          ],
        ),
      ),
    );
  }
}

// --- Step 2: Max Waiting Count ---
class StoreCapacityStep extends StatefulWidget {
  final TextEditingController maxWaitingCountController;
  final VoidCallback onNext;

  const StoreCapacityStep({
    super.key,
    required this.maxWaitingCountController,
    required this.onNext,
  });

  @override
  State<StoreCapacityStep> createState() => _StoreCapacityStepState();
}

class _StoreCapacityStepState extends State<StoreCapacityStep> {
  final _formKey = GlobalKey<FormState>();

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('最大登録可能組数',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('同時に待機登録できる最大組数を設定してください。',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            AddStoreTextField(
              controller: widget.maxWaitingCountController,
              label: '組数 (組)',
              type: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return '組数を入力してください。';
                if (int.tryParse(value) == null) return '数字のみ入力してください。';
                return null;
              },
            ),
            const SizedBox(height: 40),
            AddStoreActionButton(label: '次へ', onPressed: _handleNext),
          ],
        ),
      ),
    );
  }
}

// --- Step 3: Estimated Wait Time ---
class StoreTimeStep extends StatefulWidget {
  final TextEditingController estimatedWaitTimeController;
  final VoidCallback onNext;

  const StoreTimeStep({
    super.key,
    required this.estimatedWaitTimeController,
    required this.onNext,
  });

  @override
  State<StoreTimeStep> createState() => _StoreTimeStepState();
}

class _StoreTimeStepState extends State<StoreTimeStep> {
  final _formKey = GlobalKey<FormState>();

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('予想待機時間',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('1組あたりの予想待機時間を設定してください。',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            AddStoreTextField(
              controller: widget.estimatedWaitTimeController,
              label: '時間 (分)',
              type: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return '時間を入力してください。';
                if (int.tryParse(value) == null) return '数字のみ入力してください。';
                return null;
              },
            ),
            const SizedBox(height: 40),
            AddStoreActionButton(label: '次へ', onPressed: _handleNext),
          ],
        ),
      ),
    );
  }
}

// --- Step 4: Pre-Order ---
class StorePreOrderStep extends StatelessWidget {
  final bool isPreOrderEnabled;
  final ValueChanged<bool> onPreOrderChanged;
  final VoidCallback onNext;

  const StorePreOrderStep({
    super.key,
    required this.isPreOrderEnabled,
    required this.onPreOrderChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('メニュー事前選択',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('待機登録時にメニューの選択を必須にしますか？',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: _SelectionButton(
              label: 'はい',
              isSelected: isPreOrderEnabled,
              onTap: () {
                onPreOrderChanged(true);
                onNext();
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _SelectionButton(
              label: 'いいえ',
              isSelected: !isPreOrderEnabled,
              onTap: () {
                onPreOrderChanged(false);
                onNext();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Step 5: Review ---
class StoreReviewStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final TextEditingController maxWaitingCountController;
  final TextEditingController estimatedWaitTimeController;
  final bool isPreOrderEnabled;
  final VoidCallback onSubmit;
  final bool isLoading;

  const StoreReviewStep({
    super.key,
    required this.nameController,
    required this.addressController,
    required this.phoneController,
    required this.maxWaitingCountController,
    required this.estimatedWaitTimeController,
    required this.isPreOrderEnabled,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('入力内容の確認',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('以下の内容で店舗を登録します。',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          _buildInfoRow('店名', nameController.text),
          _buildInfoRow('住所', addressController.text),
          _buildInfoRow('電話番号', phoneController.text),
          _buildInfoRow('最大登録可能組数', '${maxWaitingCountController.text} 組'),
          _buildInfoRow('予想待機時間', '${estimatedWaitTimeController.text} 分'),
          _buildInfoRow('メニュー事前選択', isPreOrderEnabled ? 'あり' : 'なし'),
          const SizedBox(height: 40),
          AddStoreActionButton(
            label: '登録する',
            onPressed: onSubmit,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

class _SelectionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPrimary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.border,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
