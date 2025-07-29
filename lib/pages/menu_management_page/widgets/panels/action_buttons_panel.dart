import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';

class ActionButtonsPanel extends StatelessWidget {
  final bool isCategoryEmpty;
  final VoidCallback onAddCategory;
  final VoidCallback onAddMenu;
  final VoidCallback onSaveChanges;
  final VoidCallback onResetAll;

  const ActionButtonsPanel({
    super.key,
    required this.isCategoryEmpty,
    required this.onAddCategory,
    required this.onAddMenu,
    required this.onSaveChanges,
    required this.onResetAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("メニュー管理ボタン",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          _buildButton(text: "カテゴリー追加", textColor: AppColors.textPrimaryLight, onPressed: onAddCategory),
          const SizedBox(height: 16),
          _buildButton(
              text: "メニュー追加", textColor: AppColors.textPrimaryLight, onPressed: isCategoryEmpty ? null : onAddMenu),
          const Spacer(),
          _buildButton(
              text: "保存",
              textColor: AppColors.textPrimaryLight,
              onPressed: onSaveChanges,
              color: AppColors.mainAccent),
          const SizedBox(height: 16),
          _buildButton(
              text: "初期化", textColor: AppColors.error, onPressed: onResetAll, color: AppColors.cardBackground),
        ],
      ),
    );
  }

  Widget _buildButton(
      {required String text,
      required textColor,
      required VoidCallback? onPressed,
      Color? color}) {
    return SizedBox(
      width: 270,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.mainAccent,
          foregroundColor: AppColors.mainAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          disabledBackgroundColor: AppColors.mainAccent.withOpacity(0.5),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }
}
