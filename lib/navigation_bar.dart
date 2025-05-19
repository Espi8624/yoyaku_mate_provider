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
          const SizedBox(height: 20),
          // 토글 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(isExpanded ? Icons.close : Icons.arrow_forward_ios_rounded),
                onPressed: onToggle,
              ),
            ),
          ),
          const SizedBox(height: 15),

          // 프로필 섹션
          if (isExpanded) ...[
            InkWell(
              // InkWell 추가
              onTap: () => onItemTapped(4), // 프로필 탭 이벤트
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
              // 축소된 상태에서도 탭 가능하게
              onTap: () => onItemTapped(4),
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
          const SizedBox(
            height: 15
          ),

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
          const SizedBox(height: 15),

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
          const SizedBox(height: 15),

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
          const SizedBox(height: 15),

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

          const SizedBox(height: 15),

          const Spacer(), // 나머지 공간을 채움

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
