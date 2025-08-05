import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/menu_list.dart';

class MenuItemCard extends StatelessWidget {
  final MenuListItem menuItem;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MenuItemCard({
    super.key,
    required this.menuItem,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppColors.cardBackground,
      elevation: 4,
      shadowColor: AppColors.textSecondary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.border.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: _buildImage(),
        title: Text(
          menuItem.title,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            menuItem.description,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${menuItem.price.toStringAsFixed(0)}円',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
                icon: const Icon(Icons.edit,
                    size: 20, color: AppColors.textSecondary),
                onPressed: onEdit,
                tooltip: '編集'),
            IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 22, color: AppColors.error),
                onPressed: onDelete,
                tooltip: '削除'),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return SizedBox(
      width: 50,
      height: 50,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: menuItem.tempImageBytes != null
            ? Image.memory(menuItem.tempImageBytes!, fit: BoxFit.cover)
            : menuItem.imageUrl.isNotEmpty
                ? Image.network(menuItem.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        color: AppColors.textSecondary))
                : const Icon(Icons.image_not_supported,
                    color: AppColors.textSecondary),
      ),
    );
  }
}