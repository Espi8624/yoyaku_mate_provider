import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

/// 生年月日入力欄
///
/// タップするとカレンダー(showDatePicker)が開き、選択した日付を
/// "YYYY-MM-DD"形式でcontrollerにセットする読み取り専用フィールド。
/// サインアップ画面・プロフィール編集ダイアログの両方から共通で使用する
class BirthdateInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const BirthdateInputField({
    super.key,
    required this.controller,
    this.label = '生年月日',
  });

  // 労働基準法上の最低就労年齢(満15歳、中学校卒業年度末まで)を踏まえ、
  // 初期表示は20歳を基準にしつつ選択可能範囲を満15歳〜満100歳に制限する
  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = controller.text.isNotEmpty
        ? (DateTime.tryParse(controller.text) ??
            DateTime(now.year - 20, now.month, now.day))
        : DateTime(now.year - 20, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 15, now.month, now.day),
      helpText: '生年月日を選択',
    );

    if (picked != null) {
      final formatted = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
      controller.text = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _pickDate(context),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
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
          if (value == null || value.isEmpty) return '生年月日を選択してください。';
          return null;
        },
      ),
    );
  }
}
