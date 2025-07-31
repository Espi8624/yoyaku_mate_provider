import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart'; // AppColors 경로에 맞춰주세요.
import '../../../../models/menu_list.dart';
import '../menu_item_card.dart';

class MenuListPanel extends StatelessWidget {
  final TabController tabController;
  final List<String> categories;
  final Map<String, List<MenuListItem>> categorizedMenu;
  final Function(int) onEditCategory;
  final Function(int) onDeleteCategory;
  final Function(int, int) onEditMenu;
  final Function(int, int) onDeleteMenu;

  const MenuListPanel({
    super.key,
    required this.tabController,
    required this.categories,
    required this.categorizedMenu,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onEditMenu,
    required this.onDeleteMenu,
  });

  Widget _buildTab(BuildContext context, int index) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(categories[index]),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => onEditCategory(index),
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.textPrimary,
              splashRadius: 20,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => onDeleteCategory(index),
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.error,
              splashRadius: 20,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Text(
            "メニュー管理",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(0.0),
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,

              splashBorderRadius: BorderRadius.circular(30),

              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.pressed)) {
                    return AppColors.mainAccent.withOpacity(0.12);
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return AppColors.mainAccent.withOpacity(0.08);
                  }
                  return null;
                },
              ),

              indicator: const ShapeDecoration(
                color: AppColors.mainAccent,
                shape: StadiumBorder(),
              ),

              labelColor: AppColors.textPrimaryLight,
              unselectedLabelColor: AppColors.textPrimary,

              labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),

              tabs: List.generate(
                categories.length,
                (index) => _buildTab(context, index),
              ),
            ),
          ),
        if (categories.isNotEmpty)
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: categories.map((category) {
                final menuList = (categorizedMenu[category] ?? []).where((item) => item.menuStatus == 'available').toList();
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: menuList.length,
                  itemBuilder: (context, index) {
                    return MenuItemCard(
                      menuItem: menuList[index],
                      onEdit: () => onEditMenu(tabController.index, index),
                      onDelete: () => onDeleteMenu(tabController.index, index),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        if (categories.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 48,
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'カテゴリーを追加してください。',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}