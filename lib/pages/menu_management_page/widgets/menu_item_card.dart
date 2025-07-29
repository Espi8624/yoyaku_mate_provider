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
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: _buildImage(),
        title: Text(menuItem.title),
        subtitle: Text(menuItem.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${menuItem.price.toStringAsFixed(0)}円'),
            const SizedBox(width: 16),
            IconButton(
                icon: const Icon(Icons.edit,
                    size: 20, color: AppColors.textPrimary),
                onPressed: onEdit,
                tooltip: '編集'),
            IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.error),
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
