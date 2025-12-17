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
      selectedLabelStyle: const TextStyle(fontSize: 0),
      unselectedLabelStyle: const TextStyle(fontSize: 0),
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.cardBackground,
      // 各タブの定義
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(
            Icons.list_alt_rounded,
            color: AppColors.textTertiary,
          ),
          activeIcon: Icon(
            Icons.list_alt_rounded,
            color: AppColors.accentPrimary,
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.table_view_rounded,
            color: AppColors.textTertiary,
          ),
          activeIcon: Icon(
            Icons.table_view_rounded,
            color: AppColors.accentPrimary,
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.people_alt_outlined,
            color: AppColors.textTertiary,
          ),
          activeIcon: Icon(
            Icons.people_alt_rounded,
            color: AppColors.accentPrimary,
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.settings,
            color: AppColors.textTertiary,
          ),
          activeIcon: Icon(
            Icons.settings,
            color: AppColors.accentPrimary,
          ),
          label: '',
        ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.logout_rounded),
        //   label: 'ログアウト',
        // ),
      ],
    );
  }
}
