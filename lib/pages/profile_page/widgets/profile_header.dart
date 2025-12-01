import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String? imageUrl;
  final IconData? icon;
  final VoidCallback? onTapImage;
  final VoidCallback? onTapName;

  const ProfileHeader({
    super.key,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.icon,
    this.onTapImage,
    this.onTapName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: onTapImage,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? NetworkImage(imageUrl!)
                  : null,
              child: (imageUrl == null || imageUrl!.isEmpty)
                  ? Icon(icon ?? Icons.person, color: Colors.white, size: 30)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTapName,
            child: IntrinsicWidth(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  if (onTapName != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.edit, color: Colors.grey[600], size: 20),
                  ],
                ],
              ),
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(subtitle!,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}
