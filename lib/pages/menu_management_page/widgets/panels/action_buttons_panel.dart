import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class ActionButtonsPanel extends StatelessWidget {
  final bool isCategoryEmpty;
  final VoidCallback onAddCategory;
  final VoidCallback onAddMenu;
  // final VoidCallback onSaveChanges;
  final VoidCallback onResetAll;

  const ActionButtonsPanel({
    super.key,
    required this.isCategoryEmpty,
    required this.onAddCategory,
    required this.onAddMenu,
    // required this.onSaveChanges,
    required this.onResetAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "メニュー管理ボタン",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildButton(
                      onPressed: onAddCategory,
                      label: 'カテゴリー追加',
                      icon: Icons.create_new_folder_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildButton(
                      onPressed: isCategoryEmpty ? null : onAddMenu,
                      label: 'メニュー追加',
                      icon: Icons.add_shopping_cart_rounded,
                    ),
                    const Spacer(),
                    // _buildButton(
                    //   onPressed: onSaveChanges,
                    //   label: '保存',
                    //   icon: Icons.save_alt_rounded,
                    //   isPrimary: true,
                    // ),
                    const SizedBox(height: 16),
                    _buildButton(
                      onPressed: onResetAll,
                      label: '初期化',
                      icon: Icons.delete_sweep_outlined,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                : AppColors.cardBackground,
        elevation: isPrimary ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ).copyWith(
        // 非活性化された時の色を名詞的に指定
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.grey.shade300;
            }
            // isPrimary, isDestructiveなど条件によって違う色を返却
            if (isPrimary) return AppColors.accentPrimary;
            if (isDestructive) return AppColors.error.withOpacity(0.1);
            return AppColors.cardBackground;
          },
        ),
      ),
    );
  }
}
