import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/store_selection/widgets/add_store_text_field.dart';
import 'package:yoyaku_mate_provider/pages/store_selection/widgets/add_store_action_button.dart';
import 'package:yoyaku_mate_provider/services/address_service.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

// --- Step 1: 基本情報 ---
class StoreBasicInfoStep extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController zipCodeController; // 新規追加
  final TextEditingController prefectureController; // 新規追加
  final TextEditingController cityController; // 新規追加
  final TextEditingController addressController;
  final TextEditingController buildingController; // 新規追加
  final TextEditingController phoneController;
  final VoidCallback onNext;

  const StoreBasicInfoStep({
    super.key,
    required this.nameController,
    required this.zipCodeController, // 新規追加
    required this.prefectureController, // 新規追加
    required this.cityController, // 新規追加
    required this.addressController,
    required this.buildingController, // 新規追加
    required this.phoneController,
    required this.onNext,
  });

  @override
  State<StoreBasicInfoStep> createState() => _StoreBasicInfoStepState();
}

class _StoreBasicInfoStepState extends State<StoreBasicInfoStep> {
  final _formKey = GlobalKey<FormState>();
  // ローカルの _zipCodeController は削除されました
  bool _isLoadingAddress = false;

  @override
  void dispose() {
    // _zipCodeController は親ウィジェットで管理されるようになりました
    super.dispose();
  }

  Future<void> _searchAddress() async {
    final zipCode = widget.zipCodeController.text.replaceAll('-', '');
    if (zipCode.length != 7) {
      ToastWidget.show(context, '郵便番号(7桁)を入力してください', type: ToastType.error);
      return;
    }

    setState(() => _isLoadingAddress = true);
    FocusScope.of(context).unfocus();

    final service = AddressService();
    final address = await service.searchAddress(zipCode);

    if (!mounted) return;
    setState(() => _isLoadingAddress = false);

    if (address != null) {
      setState(() {
        // DB用の非表示フィールドを更新
        widget.prefectureController.text = address.prefecture;
        widget.cityController.text = address.city;

        // 表示用の住所フィールドにフルアドレスを自動入力
        // 既存のアプリに合わせてフルアドレスを使用します
        widget.addressController.text = address.fullAddress;
      });
      ToastWidget.show(context, '住所を自動入力しました', type: ToastType.success);
    } else {
      ToastWidget.show(context, '郵便番号が見つかりませんでした', type: ToastType.error);
    }
  }

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

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return '住所を入力してください。';
    }
    // 番地が含まれているかチェック ("数字...ハイフン...数字" のパターン)
    // 半角 (0-9, -) と全角 (０-９, −) に対応
    final hasBlockNumber =
        RegExp(r'[0-9０-９]+.*[-−].*[0-9０-９]+').hasMatch(value);

    if (!hasBlockNumber) {
      return '住所は番地まで正しく入力してください (例: 1-2-3)';
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
            // 郵便番号入力行
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AddStoreTextField(
                    controller: widget.zipCodeController,
                    label: '郵便番号 (ハイフンなし)',
                    type: TextInputType.number,
                    // validator: (v) => v!.isNotEmpty && v.length != 7 ? '7桁で入力' : null, // 任意のバリデーション
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 24.0), // テキストフィールドと位置を合わせる
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoadingAddress ? null : _searchAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoadingAddress
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('住所検索'),
                    ),
                  ),
                ),
              ],
            ),
            AddStoreTextField(
              controller: widget.addressController,
              label: '住所',
              validator: _validateAddress,
            ),
            AddStoreTextField(
              controller: widget.buildingController,
              label: '建物名・部屋番号 (任意)',
              validator: null, // 任意
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

// --- Step 2: 最大待機組数 ---
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

// --- Step 3: 予想待機時間 ---
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

// --- Step 4: メニュー事前選択 ---
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

// --- Step 4.5: 1人1メニュー制 (新規追加) ---
class StoreOneMenuRuleStep extends StatelessWidget {
  final bool requireOneMenuPerPerson;
  final ValueChanged<bool> onRequireRuleChanged;
  final VoidCallback onNext;

  const StoreOneMenuRuleStep({
    super.key,
    required this.requireOneMenuPerPerson,
    required this.onRequireRuleChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('1人1メニュー制',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // ユーザーリクエストに合わせて明確な説明に変更
          const Text('来店人数分のメニュー注文を必須にしますか？',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: _SelectionButton(
              label: 'はい',
              isSelected: requireOneMenuPerPerson,
              onTap: () {
                onRequireRuleChanged(true);
                onNext();
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _SelectionButton(
              label: 'いいえ',
              isSelected: !requireOneMenuPerPerson,
              onTap: () {
                onRequireRuleChanged(false);
                onNext();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Step 5: 確認画面 ---
class StoreReviewStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController buildingController; // 新規追加
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
    required this.buildingController, // 新規追加
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
          _buildInfoRow(
              '住所', '${addressController.text} ${buildingController.text}'),
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
