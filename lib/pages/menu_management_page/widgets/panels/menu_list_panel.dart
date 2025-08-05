import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart'; // AppColors 경로를 프로젝트에 맞게 확인해주세요.
import '../../../../models/menu_list.dart'; // MenuListItem 모델 경로를 프로젝트에 맞게 확인해주세요.
import '../menu_item_card.dart'; // MenuItemCard 위젯 경로를 프로젝트에 맞게 확인해주세요.

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
        // --- 페이지 제목 ---
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

        // --- 카테고리가 있을 경우에만 TabBar와 TabBarView를 표시 ---
        if (categories.isNotEmpty) ...[
          // --- TabBar 섹션 ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // 좌우 여백 추가
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              dividerColor: Colors.transparent, // 기본 구분선 제거
              indicatorSize: TabBarIndicatorSize.tab, // 인디케이터 크기를 탭에 맞춤

              // 탭을 눌렀을 때 효과 (Ripple)
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

              // 선택된 탭의 인디케이터 디자인
              indicator: const ShapeDecoration(
                color: AppColors.accentPrimary,
                shape: StadiumBorder(),
              ),

              // 텍스트 색상
              labelColor: AppColors.textPrimaryLight,
              unselectedLabelColor: AppColors.textPrimary,

              // 텍스트 스타일 (두께 조절로 시각적 차이 부여)
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),

              // 각 탭 사이의 기본 패딩
              labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),

              // [핵심 로직] 탭 목록 생성
              tabs: List.generate(categories.length, (index) {
                // 현재 탭의 선택 여부 판단
                final bool isSelected = tabController.index == index;
                // 선택 상태에 따라 아이콘 색상 결정
                final Color iconColor = isSelected
                    ? AppColors.textPrimaryLight
                    : AppColors.textPrimary;

                return Tab(
                  child: Padding(
                    // 탭 내부 요소들의 패딩
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(categories[index]),
                        const SizedBox(width: 12),
                        // [수정 완료] 아이콘 색상을 동적으로 변경
                        IconButton(
                          onPressed: () => onEditCategory(index),
                          // Icon 위젯에 직접 색상 지정
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: iconColor),
                          splashRadius: 20,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          tooltip: 'カテゴリー編集', // 툴팁 추가 (웹/데스크탑 환경에서 유용)
                        ),
                        const SizedBox(width: 4),
                        // 삭제 아이콘은 항상 error 색상 유지
                        IconButton(
                          onPressed: () => onDeleteCategory(index),
                          icon: const Icon(Icons.close,
                              size: 18, color: AppColors.error),
                          splashRadius: 20,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          tooltip: 'カテゴリー削除', // 툴팁 추가
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // --- TabBarView (탭 컨텐츠) ---
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: categories.map((category) {
                // 'available' 상태의 메뉴만 필터링
                final menuList = (categorizedMenu[category] ?? [])
                    .where((item) => item.menuStatus == 'available')
                    .toList();

                return ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(24, 24, 24, 80), // 하단 패딩 확보
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

        // --- 카테고리가 없을 경우 표시되는 화면 ---
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
