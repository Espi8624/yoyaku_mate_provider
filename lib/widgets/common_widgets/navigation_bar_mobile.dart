import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class NavigationBarMobile extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final bool isManager;

  const NavigationBarMobile({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.isManager = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalHeight = 60.0 + bottomPadding;

    return Container(
      height: totalHeight,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildNavItem(0, Icons.list_alt_rounded, Icons.list_alt_rounded),
            _buildNavItem(
                1, Icons.table_view_rounded, Icons.table_view_rounded),
            _buildNavItem(2, Icons.bar_chart_rounded, Icons.bar_chart_rounded),
            if (isManager)
              _buildNavItem(
                  3, Icons.people_alt_outlined, Icons.people_alt_rounded),
            _buildNavItem(isManager ? 4 : 3, Icons.settings, Icons.settings),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onItemTapped(index),
        splashColor: AppColors.accentPrimary.withOpacity(0.05),
        highlightColor: AppColors.accentPrimary.withOpacity(0.02),
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
          child: Icon(
            isSelected ? activeIcon : icon,
            color:
                isSelected ? AppColors.accentPrimary : AppColors.textTertiary,
            size: 28,
          ),
        ),
      ),
    );
  }
}
