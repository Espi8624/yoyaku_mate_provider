import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

// 設定セクションのタイトルを生成するウィジェット関数
Widget buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
    child: Text(
      title,
      style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary),
    ),
  );
}

// 設定項目を1行で表示するウィジェット関数
Widget buildSettingItem({
  required String title,
  required String subtitle,
  required VoidCallback? onTap,
}) {
  return ListTile(
    title: Text(title,
        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
    subtitle: Text(subtitle,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );
}

// セクションを囲む共通コンテナウィジェット関数
Widget sectionBox({required Widget child}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: child,
  );
}
