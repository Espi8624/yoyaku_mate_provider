import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class WaitingActionButtons extends StatelessWidget {
  final VoidCallback onAddWaiting;
  final VoidCallback onClearAll;

  const WaitingActionButtons({
    super.key,
    required this.onAddWaiting,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Tooltip(
          message: "新しい待機追加",
          child: ElevatedButton(
            onPressed: onAddWaiting,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              minimumSize: Size.zero,
            ),
            child: const Icon(Icons.person_add_alt_1, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "待機目録初期化",
          child: ElevatedButton(
            onPressed: onClearAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              minimumSize: Size.zero,
            ),
            child: const Icon(Icons.delete_sweep, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
