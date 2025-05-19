import 'package:flutter/material.dart';

class SideNavigationBar extends StatelessWidget {
  final bool isExpanded;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onToggle;

  const SideNavigationBar({
    super.key,
    required this.isExpanded,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      // width: isExpanded ? 220 : 60,
      // color: Colors.grey[200],
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFCF2F3), // 연한 핑크/살구
            Color(0xFFEDB6B0), // 코랄
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x99EDB6B0), // 그림자 색상
            blurRadius: 12, // 그림자 퍼짐 정도
            offset: Offset(2, 0), // x=4, y=0 → 오른쪽으로만 그림자
            spreadRadius: 0.1, // 그림자 확장 정도
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: onToggle,
          ),
          const SizedBox(height: 40),
          // 店舗状況
          isExpanded
              ? _NavItem(
                  icon: Icons.newspaper_rounded,
                  label: '店舗状況',
                  selected: selectedIndex == 0,
                  onTap: () => onItemTapped(0),
                )
              : _NavIcon(
                  icon: Icons.newspaper_rounded,
                  selected: selectedIndex == 0,
                  label: '店舗状況',
                  onTap: () => onItemTapped(0),
                  isExpanded: isExpanded,
                ),
          const SizedBox(height: 20),

          // ウェイティングリスト
          isExpanded
              ? _NavItem(
                  icon: Icons.list_alt_rounded,
                  label: 'ウェイティングリスト',
                  selected: selectedIndex == 1,
                  onTap: () => onItemTapped(1),
                )
              : _NavIcon(
                  icon: Icons.list_alt_rounded,
                  selected: selectedIndex == 1,
                  label: 'ウェイティングリスト',
                  onTap: () => onItemTapped(1),
                  isExpanded: isExpanded,
                ),
          const SizedBox(height: 20),

          // 売上管理
          isExpanded
              ? _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: '売上管理',
                  selected: selectedIndex == 2,
                  onTap: () => onItemTapped(2),
                )
              : _NavIcon(
                  icon: Icons.bar_chart_rounded,
                  selected: selectedIndex == 2,
                  label: '売上管理',
                  onTap: () => onItemTapped(2),
                  isExpanded: isExpanded,
                ),
          const SizedBox(height: 20),

          // メニュー管理
          isExpanded
              ? _NavItem(
                  icon: Icons.table_view_rounded,
                  label: 'メニュー管理',
                  selected: selectedIndex == 3,
                  onTap: () => onItemTapped(3),
                )
              : _NavIcon(
                  icon: Icons.table_view_rounded,
                  selected: selectedIndex == 3,
                  label: 'メニュー管理',
                  onTap: () => onItemTapped(3),
                  isExpanded: isExpanded,
                ),

          const SizedBox(height: 20),
          const Spacer(),
          // プロフィール
          isExpanded
              ? _NavItem(
                  icon: Icons.person,
                  label: 'プロフィール',
                  selected: selectedIndex == 4,
                  onTap: () => onItemTapped(4),
                )
              : _NavIcon(
                  icon: Icons.person,
                  selected: selectedIndex == 4,
                  label: 'プロフィール',
                  onTap: () => onItemTapped(4),
                  isExpanded: isExpanded,
                ),
          const SizedBox(height: 20),
          // 設定
          isExpanded
              ? _NavItem(
                  icon: Icons.settings,
                  label: '設定',
                  selected: selectedIndex == 5,
                  onTap: () => onItemTapped(5),
                )
              : _NavIcon(
                  icon: Icons.settings,
                  selected: selectedIndex == 5,
                  label: '設定',
                  onTap: () => onItemTapped(5),
                  isExpanded: isExpanded,
                ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon,
              color: selected ? const Color(0xFFFF6F61) : Colors.grey[600]),
          onPressed: onTap,
        ),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: selected ? const Color(0xFFFF6F61) : Colors.grey[600])),
      ],
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isExpanded;

  const _NavIcon(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap,
      required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon,
              color: selected ? const Color(0xFFE57373) : Colors.grey[600]),
          onPressed: onTap,
        ),
      ],
    );
  }
}
