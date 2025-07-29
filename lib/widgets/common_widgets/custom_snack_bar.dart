import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

enum SnackBarStatus { success, error, info }

class CustomSnackBar {
  static void show(BuildContext context, {required String message, SnackBarStatus status = SnackBarStatus.info}) {
    Color backgroundColor;
    switch (status) {
      case SnackBarStatus.success:
        backgroundColor = AppColors.success;
        break;
      case SnackBarStatus.error:
        backgroundColor = AppColors.error;
        break;
      case SnackBarStatus.info:
      default:
        backgroundColor = AppColors.cardBackground;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}