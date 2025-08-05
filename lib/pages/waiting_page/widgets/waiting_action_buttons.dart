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
        ElevatedButton.icon(
          icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
          label: const Text("新しい待機追加", style: TextStyle(color: Colors.white)),
          onPressed: onAddWaiting,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.white),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_sweep, color: Colors.white),
          label: const Text("待機目録初期化", style: TextStyle(color: Colors.white)),
          onPressed: onClearAll,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error, foregroundColor: Colors.white),
        ),
      ],
    );
  }
}
