import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final bool isLineButton;

  const ActionButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.label = '次へ',
    this.isLineButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isLineButton ? const Color(0xFF00B900) : AppColors.textPrimary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
          enableFeedback: false,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white))
            else ...[
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              if (!isLineButton) const SizedBox(width: 8),
              if (!isLineButton) const Icon(Icons.arrow_forward_ios, size: 16),
            ]
          ],
        ),
      ),
    );
  }
}
