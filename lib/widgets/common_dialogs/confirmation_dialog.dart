import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = '削除',
}) async {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
        
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(content, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                foregroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                  if (states.contains(WidgetState.hovered)) {
                    return AppColors.error.withOpacity(0.8);
                  }
                  return AppColors.error; 
                }),
              ),
              child: Text(
                confirmText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    },
  );
}