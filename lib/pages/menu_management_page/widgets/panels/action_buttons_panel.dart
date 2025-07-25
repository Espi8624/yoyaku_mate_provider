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
      color: AppColors.primaryBackground.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("メニュー管理ボタン",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText)),
          const SizedBox(height: 24),
          _buildButton(text: "カテゴリー追加", onPressed: onAddCategory),
          const SizedBox(height: 16),
          _buildButton(
              text: "メニュー追加", onPressed: isCategoryEmpty ? null : onAddMenu),
          const Spacer(),
          _buildButton(
              text: "保存",
              onPressed: onSaveChanges,
              color: AppColors.secondaryAction),
          const SizedBox(height: 16),
          _buildButton(
              text: "初期化", onPressed: onResetAll, color: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildButton(
      {required String text, required VoidCallback? onPressed, Color? color}) {
    return SizedBox(
      width: 270,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.secondaryAction,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          disabledBackgroundColor: AppColors.lightGrey,
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}
