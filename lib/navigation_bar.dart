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
      duration: const Duration(milliseconds: 200),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // 토글 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                    isExpanded ? Icons.close : Icons.arrow_forward_ios_rounded),
                onPressed: onToggle,
              ),
            ),
          ),
          const SizedBox(height: 15),

          // 프로필 섹션
          if (isExpanded) ...[
            InkWell(
              onTap: () {
                onItemTapped(1);
                onToggle();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person,
                          size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "川崎食堂",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            InkWell(
              onTap: () => onItemTapped(1),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 24, color: Colors.white),
              ),
            ),
          ],
          const SizedBox(height: 15),

          // 프로필 구분선
          const Divider(
            height: 1,
            thickness: 0.5,
            color: Color(0xFF263238),
            indent: 16,
            endIndent: 16,
          ),
          const SizedBox(height: 15),

          // 店舗状況
          isExpanded
              ? _NavItem(
                  icon: Icons.newspaper_rounded,
                  label: '店舗状況',
                  selected: selectedIndex == 0,
                  onTap: () {
                    onItemTapped(0);
                    onToggle();
                  },
                )
              : _NavIcon(
                  icon: Icons.newspaper_rounded,
                  selected: selectedIndex == 0,
                  label: '店舗状況',
                  onTap: () => onItemTapped(0),
                  isExpanded: isExpanded,
                ),
          const SizedBox(height: 15),

          // 待機リスト
          isExpanded
              ? _NavItem(
                  icon: Icons.list_alt_rounded,
                  label: '待機リスト',
                  selected: selectedIndex == 2,
                  onTap: () {
                    onItemTapped(2);
                    onToggle();
                  },
                )
              : _NavIcon(
                  icon: Icons.list_alt_rounded,
                  selected: selectedIndex == 2,
                  label: '待機リスト',
                  onTap: () => onItemTapped(2),
                  isExpanded: isExpanded,
                ),
          const SizedBox(height: 15),

          // 売上入力
          isExpanded
              ? _NavItem(
                  icon: Icons.library_books_rounded,
                  label: '売出入力',
                  selected: selectedIndex == 3,
                  onTap: () {
                    onItemTapped(3);
                    onToggle();
                  },
                )
              : _NavIcon(
                  icon: Icons.library_books_rounded,
                  selected: selectedIndex == 3,
                  label: '売上入力',
                  onTap: () => onItemTapped(3),
                  isExpanded: isExpanded,
                ),
          const SizedBox(height: 15),

          // 売上管理
          isExpanded
              ? _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: '売出管理',
                  selected: selectedIndex == 4,
                  onTap: () {
                    onItemTapped(4);
                    onToggle();
                  },
                )
              : _NavIcon(
                  icon: Icons.bar_chart_rounded,
                  selected: selectedIndex == 4,
                  label: '売上管理',
                  onTap: () => onItemTapped(4),
                  isExpanded: isExpanded,
                ),
          const SizedBox(height: 15),

          // メニュー管理
          isExpanded
              ? _NavItem(
                  icon: Icons.table_view_rounded,
                  label: 'メニュー管理',
                  selected: selectedIndex == 5,
                  onTap: () {
                    onItemTapped(5);
                    onToggle();
                  },
                )
              : _NavIcon(
                  icon: Icons.table_view_rounded,
                  selected: selectedIndex == 5,
                  label: 'メニュー管理',
                  onTap: () => onItemTapped(5),
                  isExpanded: isExpanded,
                ),
          const SizedBox(height: 15),

          const Spacer(),

          // 設定
          isExpanded
              ? _NavItem(
                  icon: Icons.settings,
                  label: '設定',
                  selected: selectedIndex == 6,
                  onTap: () {
                    onItemTapped(6);
                    onToggle();
                  },
                )
              : _NavIcon(
                  icon: Icons.settings,
                  selected: selectedIndex == 6,
                  label: '設定',
                  onTap: () => onItemTapped(6),
                  isExpanded: isExpanded,
                ),
          const SizedBox(height: 15),

          // 로그아웃 버튼 구분선
          const Divider(
            height: 1,
            thickness: 0.5,
            color: Color(0xFF263238),
            indent: 16,
            endIndent: 16,
          ),
          const SizedBox(height: 10),

          isExpanded
              ? _NavItem(
                  icon: Icons.logout,
                  label: 'ログアウト',
                  selected: null,
                  onTap: () {},
                )
              : _NavIcon(
                  icon: Icons.logout,
                  selected: null,
                  label: 'ログアウト',
                  onTap: () {},
                  isExpanded: isExpanded,
                ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool? selected;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ?? false
                  ? const Color(0xFFFF6F61)
                  : Colors.grey[600],
            ),
            const SizedBox(width: 12), // 아이콘과 텍스트 사이 간격
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: selected ?? false
                    ? const Color(0xFFFF6F61)
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool? selected;
  final VoidCallback? onTap;
  final bool isExpanded;

  const _NavIcon(
      {required this.icon,
      required this.label,
      this.selected,
      this.onTap,
      required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon,
              color: selected ?? false
                  ? const Color(0xFFE57373)
                  : Colors.grey[600]),
          onPressed: onTap,
        ),
      ],
    );
  }
}
