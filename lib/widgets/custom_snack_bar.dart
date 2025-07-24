import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SnackBarStatus { success, error, warning, info }

class CustomSnackBar {
  static Color _getBackgroundColor(SnackBarStatus status, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    switch (status) {
      case SnackBarStatus.success:
        return isDarkMode
            ? Colors.green.shade800.withOpacity(0.85)
            : Colors.green.shade100.withOpacity(0.9);
      case SnackBarStatus.error:
        return isDarkMode
            ? Colors.red.shade800.withOpacity(0.85)
            : Colors.red.shade100.withOpacity(0.9);
      case SnackBarStatus.warning:
        return isDarkMode
            ? Colors.orange.shade800.withOpacity(0.85)
            : Colors.orange.shade100.withOpacity(0.9);
      case SnackBarStatus.info:
        return isDarkMode
            ? const Color(0xFF263238).withOpacity(0.85)
            : const Color(0xFF263238).withOpacity(0.9);
    }
  }

  static Color _getTextColor(SnackBarStatus status, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    switch (status) {
      case SnackBarStatus.success:
        return isDarkMode ? Colors.green.shade50 : Colors.green.shade900;
      case SnackBarStatus.error:
        return isDarkMode ? Colors.red.shade50 : Colors.red.shade900;
      case SnackBarStatus.warning:
        return isDarkMode ? Colors.orange.shade50 : Colors.orange.shade900;
      case SnackBarStatus.info:
        return isDarkMode ? Colors.white : Colors.grey.shade50;
    }
  }

  static IconData _getIcon(SnackBarStatus status) {
    switch (status) {
      case SnackBarStatus.success:
        return Icons.check_circle_rounded;
      case SnackBarStatus.error:
        return Icons.error_rounded;
      case SnackBarStatus.warning:
        return Icons.warning_rounded;
      case SnackBarStatus.info:
        return Icons.info_rounded;
    }
  }

  static void show(
    BuildContext context, {
    required String message,
    required SnackBarStatus status,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    bool withHapticFeedback = true,
    bool withVoiceFeedback = false,
  }) {
    final theme = Theme.of(context);

    if (withHapticFeedback) {
      switch (status) {
        case SnackBarStatus.error:
          HapticFeedback.heavyImpact();
          break;
        case SnackBarStatus.warning:
          HapticFeedback.mediumImpact();
          break;
        default:
          HapticFeedback.lightImpact();
      }
    }

    if (withVoiceFeedback) {
      // TODO: flutter_tts パッケージで音声フィードバックを実装可能
    }

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          label: '${status.toString().split('.').last}: $message',
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: _getBackgroundColor(status, theme),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: theme.brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.shade400.withOpacity(0.2),
                  blurRadius: 8.0,
                  spreadRadius: 1.0,
                  offset: const Offset(2, 2),
                ),
                BoxShadow(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.5),
                  blurRadius: 8.0,
                  spreadRadius: 1.0,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _getIcon(status),
                  color: _getTextColor(status, theme),
                  size: 24.0,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _getTextColor(status, theme),
                      fontWeight: FontWeight.w600,
                      fontSize: 16.0,
                    ),
                    textScaler: const TextScaler.linear(1.0),
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        elevation: 0,
        duration: duration,
        animation: CurvedAnimation(
          parent: kAlwaysCompleteAnimation,
          curve: Curves.elasticOut,
        ),
        action: action,
      ),
    );
  }
}
