import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text("メニュー管理", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
        ),
        if (categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              indicator: BoxDecoration(color: AppColors.secondaryAction, borderRadius: BorderRadius.circular(32)),
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.primaryText,
              tabs: List.generate(categories.length, (index) {
                return Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.secondaryAction)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(categories[index]),
                        const SizedBox(width: 12),
                        InkWell(onTap: () => onEditCategory(index), child: const Icon(Icons.edit, size: 16, color: AppColors.mediumGrey)),
                        const SizedBox(width: 8),
                        InkWell(onTap: () => onDeleteCategory(index), child: const Icon(Icons.close, size: 16, color: AppColors.error)),
                      ],
                    ),
                  ),
                );
              }),
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
              child: Text('カテゴリーを追加してください。', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            ),
          ),
      ],
    );
  }
}