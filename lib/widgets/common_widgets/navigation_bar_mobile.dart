import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class NavigationBarMobile extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const NavigationBarMobile({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      selectedItemColor: AppColors.accentPrimary,
      unselectedItemColor: AppColors.textSecondary.withOpacity(0.8),
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.cardBackground,
      // 各タブの定義
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_rounded),
          label: '待機リスト',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.table_view_rounded),
          label: 'メニュー管理',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person),
          label: 'プロフィール',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings_rounded),
          label: '設定',
        ),
      ],
    );
  }
}
