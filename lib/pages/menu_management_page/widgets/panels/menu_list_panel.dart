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
        // const Padding(
        //   padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
        //   child: Text(
        //     "メニュー管理",
        //     style: TextStyle(
        //       fontSize: 24,
        //       fontWeight: FontWeight.bold,
        //       color: AppColors.textPrimary,
        //     ),
        //   ),
        // ),

        // カテゴリが存在する場合、TabBar, TabBarViewを表示
        if (categories.isNotEmpty) ...[
          TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            dividerColor: Colors.transparent,
            // indicatorサイズをTabに合わせる
            indicatorSize: TabBarIndicatorSize.tab,
            splashBorderRadius: BorderRadius.circular(30),
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.pressed)) {
                  return AppColors.accentPrimary.withOpacity(0.12);
                }
                if (states.contains(WidgetState.hovered)) {
                  return AppColors.accentPrimary.withOpacity(0.08);
                }
                return null;
              },
            ),

            // 選択されたTabのindicatorデザイン
            indicator: const ShapeDecoration(
              color: AppColors.accentPrimary,
              shape: StadiumBorder(),
            ),
            labelColor: AppColors.textPrimaryLight,
            unselectedLabelColor: AppColors.textPrimary,

            labelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),

            // Tabの間の基本Padding
            labelPadding: EdgeInsets.zero,

            // Tab List生成
            tabs: List.generate(categories.length, (index) {
              final bool isSelected = tabController.index == index;
              final Color editIconColor = isSelected
                  ? AppColors.textPrimaryLight
                  : AppColors.textSecondary;
              final Color deleteIconColor = isSelected
                  ? AppColors.error
                  : AppColors.error.withOpacity(0.6);

              return Tab(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 0.0, 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(categories[index]),
                      const SizedBox(width: 2),
                      Transform.translate(
                        offset: const Offset(8, 0),
                        child: _buildTabIconButton(
                          icon: Icons.edit,
                          color: editIconColor,
                          tooltip: 'カテゴリー編集',
                          onPressed: () => onEditCategory(index),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(-4, 0),
                        child: _buildTabIconButton(
                          icon: Icons.delete_outline,
                          color: deleteIconColor,
                          tooltip: 'カテゴリー削除',
                          onPressed: () => onDeleteCategory(index),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: categories.map((category) {
                // ステータス'available'のメニューのみフィルタリング
                final menuList = (categorizedMenu[category] ?? [])
                    .where((item) => item.menuStatus == 'available')
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
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
        ],

        // カテゴリが存在しない場合の画面
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

  // Icon Button
  Widget _buildTabIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: color,
        splashRadius: 14,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
      ),
    );
  }
}
