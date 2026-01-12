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
    // mobile layout break point設定
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Card(
      margin: EdgeInsets.symmetric(
        vertical: 8,
        horizontal: isMobile ? 0 : 16,
      ),
      color: AppColors.cardBackground,
      elevation: 4,
      shadowColor: AppColors.textSecondary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withOpacity(0.4), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildImage(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        menuItem.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (menuItem.isPreOrderAvailable) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Colors
                              .amber, // Use standard amber for "yellow" star
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (menuItem.description.isNotEmpty) ...[
                    Text(
                      menuItem.description,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  // mobile時、価格を下に表示
                  if (isMobile) _buildPriceTag(),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // desktop時価格を右に表示
            if (!isMobile) _buildPriceTag(),

            const SizedBox(width: 4),
            // 編集/削除ボタン
            _buildActionButtons(),
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
            : menuItem.menuImageUrl.isNotEmpty
                ? Image.network(menuItem.menuImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        color: AppColors.textSecondary))
                : const Icon(Icons.image_not_supported,
                    color: AppColors.textSecondary),
      ),
    );
  }

  // 価格Widget
  Widget _buildPriceTag() {
    return Text(
      '${menuItem.price.toStringAsFixed(0)}円',
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }

  // 編集/削除ボタンWidget
  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon:
              const Icon(Icons.edit, size: 20, color: AppColors.textSecondary),
          onPressed: onEdit,
          splashRadius: 20,
          tooltip: '編集',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline,
              size: 22, color: AppColors.error),
          onPressed: onDelete,
          splashRadius: 20,
          tooltip: '削除',
        ),
      ],
    );
  }
}
