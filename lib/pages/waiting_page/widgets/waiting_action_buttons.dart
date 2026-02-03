import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class WaitingActionButtons extends StatelessWidget {
  final VoidCallback onAddWaiting;
  final VoidCallback onShowMonitor;

  const WaitingActionButtons({
    super.key,
    required this.onAddWaiting,
    required this.onShowMonitor,
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
              padding: const EdgeInsets.all(12),
              minimumSize: const Size(48, 48),
            ),
            child: const Icon(Icons.person_add_alt_1, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "待機モニターURL",
          child: ElevatedButton(
            onPressed: onShowMonitor,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary, // 削除の赤色から通常色へ変更
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
              minimumSize: const Size(48, 48),
            ),
            child: const Icon(Icons.monitor, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
