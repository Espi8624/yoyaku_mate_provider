import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class ProfileSettingItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showTrailingIcon;

  const ProfileSettingItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showTrailingIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 13, color: Colors.grey)),
      trailing: showTrailingIcon ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
