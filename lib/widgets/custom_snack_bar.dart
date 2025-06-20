import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SnackBarStatus { success, error, warning, info }

class CustomSnackBar {
  static Color _getBackgroundColor(SnackBarStatus status, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    switch (status) {
      case SnackBarStatus.success:
        return isDarkMode
            ? Colors.green.shade700.withOpacity(0.3)
            : Colors.green.shade200.withOpacity(0.3);
      case SnackBarStatus.error:
        return isDarkMode
            ? Colors.red.shade700.withOpacity(0.3)
            : Colors.red.shade200.withOpacity(0.3);
      case SnackBarStatus.warning:
        return isDarkMode
            ? Colors.orange.shade700.withOpacity(0.3)
            : Colors.orange.shade200.withOpacity(0.3);
      case SnackBarStatus.info:
        return isDarkMode
            ? Colors.blue.shade700.withOpacity(0.3)
            : Colors.blue.shade200.withOpacity(0.3);
    }
  }

  static Color _getTextColor(SnackBarStatus status, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    switch (status) {
      case SnackBarStatus.success:
        return isDarkMode ? Colors.green.shade100 : Colors.green.shade900;
      case SnackBarStatus.error:
        return isDarkMode ? Colors.red.shade100 : Colors.red.shade900;
      case SnackBarStatus.warning:
        return isDarkMode ? Colors.orange.shade100 : Colors.orange.shade900;
      case SnackBarStatus.info:
        return isDarkMode ? Colors.blue.shade100 : Colors.blue.shade900;
    }
  }

  static IconData? _getIcon(SnackBarStatus status) {
    switch (status) {
      case SnackBarStatus.success:
        return Icons.check_circle_outline;
      case SnackBarStatus.error:
        return Icons.error_outline;
      case SnackBarStatus.warning:
        return Icons.warning_amber_outlined;
      case SnackBarStatus.info:
        return Icons.info_outline;
    }
  }

  static void show(
    BuildContext context, {
    required String message, // messageKey 대신 message로 변경, 하드코딩된 문자열 사용
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
        default:
          HapticFeedback.lightImpact();
      }
    }

    if (withVoiceFeedback) {
      // TODO: flutter_tts 패키지로 음성 피드백 구현 가능
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          label: '${status.toString().split('.').last} SnackBar: $message',
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: _getBackgroundColor(status, theme),
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: _getBackgroundColor(status, theme).withOpacity(0.3),
                width: 1.5,
              ),
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
                    style: TextStyle(
                      color: _getTextColor(status, theme),
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
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
        margin: const EdgeInsets.all(16.0),
        elevation: 0,
        duration: duration,
        animation: CurvedAnimation(
          parent: kAlwaysCompleteAnimation,
          curve: Curves.easeInOutCubic,
        ),
        action: action,
      ),
    );
  }
}
