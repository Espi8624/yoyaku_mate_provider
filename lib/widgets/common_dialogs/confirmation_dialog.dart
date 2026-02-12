import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/base_dialog.dart';
import '../../constants/app_colors.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = '削除',
  String? cancelText = 'キャンセル',
  bool isDestructive = true,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return BaseDialog(
        title: title,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              content,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: isDestructive
                      ? TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ButtonStyle(
                            overlayColor:
                                WidgetStateProperty.all(Colors.transparent),
                            padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(vertical: 16)),
                            foregroundColor:
                                WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                              if (states.contains(WidgetState.hovered)) {
                                return AppColors.error.withOpacity(0.8);
                              }
                              return AppColors.error;
                            }),
                          ),
                          child: Text(
                            confirmText,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            confirmText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
