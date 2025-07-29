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

  // [리팩토링 팁] 복잡한 위젯은 별도 함수로 분리하면 가독성이 좋아집니다.
  Widget _buildTab(BuildContext context, int index) {
    return Tab(
      child: Padding(
        // 탭 내부의 여백을 조절하여 더 균형 잡힌 모양을 만듭니다.
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(categories[index]),
            const SizedBox(width: 12),
            // [UX 개선] InkWell+Icon 대신 IconButton을 사용합니다.
            // - 터치 영역이 넓어지고, 시각적 피드백(물결 효과)이 제공됩니다.
            // - constraints와 padding으로 불필요한 여백을 제거하여 컴팩트하게 만듭니다.
            IconButton(
              onPressed: () => onEditCategory(index),
              icon: const Icon(Icons.edit_outlined, size: 18), // 좀 더 부드러운 외곽선 아이콘 사용
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
        // 제목 부분은 시각적 여유를 주기 위해 상하 여백을 조절합니다.
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

              // [핵심 1] 호버/클릭 시의 물결 효과를 둥글게 만듭니다.
              // StadiumBorder와 동일한 효과를 내기 위해 충분히 큰 값을 줍니다.
              splashBorderRadius: BorderRadius.circular(30),

              // [디자인 개선] 호버/클릭 시의 색상을 부드럽게 설정합니다.
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  // 클릭(pressed) 상태일 때
                  if (states.contains(WidgetState.pressed)) {
                    return AppColors.mainAccent.withOpacity(0.12);
                  }
                  // 마우스 호버(hovered) 상태일 때
                  if (states.contains(WidgetState.hovered)) {
                    return AppColors.mainAccent.withOpacity(0.08);
                  }
                  // 그 외의 경우는 색상 없음
                  return null;
                },
              ),

              // [디자인 개선] 선택된 탭의 배경을 좀 더 부드러운 '알약' 형태로 만듭니다.
              // ShapeDecoration과 StadiumBorder를 사용하면 완벽한 알약 모양이 나옵니다.
              indicator: const ShapeDecoration(
                color: AppColors.mainAccent, // mainAccent로 변경 (또는 accent)
                shape: StadiumBorder(),
              ),

              // [가독성 향상] 선택된 탭의 텍스트 색상을 흰색으로 하여 명확하게 구분합니다.
              labelColor: AppColors.textPrimaryLight, // 배경이 어두우니 흰색 텍스트로
              unselectedLabelColor: AppColors.textPrimary,

              // [디자인 개선] 불필요한 테두리를 제거하고 탭 사이의 간격을 조절합니다.
              // 모든 탭에 테두리가 있으면 시각적으로 매우 복잡해 보입니다.
              // labelPadding으로 탭 사이의 수평 간격을 조절할 수 있습니다.
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
                // 이 부분은 로직이 좋아서 그대로 유지합니다.
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
        // [디자인 개선] 비어있는 화면에 아이콘을 추가하여 더 친절하게 안내합니다.
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