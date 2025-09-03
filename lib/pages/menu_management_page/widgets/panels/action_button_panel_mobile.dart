import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class ActionButtonsPanelMobile extends StatelessWidget {
  final bool isCategoryEmpty;
  final VoidCallback onAddCategory;
  final VoidCallback onAddMenu;
  final VoidCallback onSaveChanges;
  final VoidCallback onResetAll;

  const ActionButtonsPanelMobile({
    super.key,
    required this.isCategoryEmpty,
    required this.onAddCategory,
    required this.onAddMenu,
    required this.onSaveChanges,
    required this.onResetAll,
  });

  @override
  Widget build(BuildContext context) {
    // 下段パネルのbackgroun color, shadowを定義
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          )),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  onPressed: onAddCategory,
                  label: 'カテゴリー追加',
                  icon: Icons.add,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildButton(
                  // カテゴリが存在していない場合メニュー追加ボタンを非活性化
                  onPressed: isCategoryEmpty ? null : onAddMenu,
                  label: 'メニュー追加',
                  icon: Icons.add,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  onPressed: onSaveChanges,
                  label: '保存',
                  icon: Icons.save_alt_outlined,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildButton(
                  onPressed: onResetAll,
                  label: '初期化',
                  icon: Icons.delete_outline,
                  isDestructive: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: isPrimary
            ? Colors.white
            : isDestructive
                ? AppColors.error
                : AppColors.textPrimary,
        backgroundColor: isPrimary
            ? AppColors.accentPrimary
            : isDestructive
                ? AppColors.error.withOpacity(0.1)
                : AppColors.background,
        elevation: isPrimary ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
