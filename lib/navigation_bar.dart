import 'package:flutter/material.dart';

class SideNavigationBar extends StatelessWidget {
  final bool isExpanded;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onToggle;
  final String userName;
  final String storeName;
  final String userRole; // "管理者" 또는 "スタッフ"

  const SideNavigationBar({
    super.key,
    required this.isExpanded,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onToggle,
    required this.userName,
    required this.storeName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: isExpanded ? 280 : 80,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6F61).withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // 토글 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(
                    isExpanded ? Icons.close : Icons.menu_rounded,
                    color: Colors.grey[700],
                    size: 28,
                  ),
                  onPressed: onToggle,
                  splashRadius: 20,
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 프로필 섹션
            if (isExpanded) ...[
              InkWell(
                onTap: () {
                  onItemTapped(2);
                  onToggle();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: selectedIndex == 2
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF6F61).withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[300],
                          child: const Icon(Icons.person,
                              size: 30, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: userRole == "manager"
                                        ? const Color(0xFFEF5350)
                                        : const Color(0xFF42A5F5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    userRole == "manager" ? "管理者" : "職員",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              storeName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              InkWell(
                onTap: () => onItemTapped(2),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: selectedIndex == 2
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF6F61).withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipOval(
                        child: Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey[300],
                          child: const Icon(Icons.person,
                              size: 24, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: userRole == "manager"
                                ? const Color(0xFFEF5350)
                                : const Color(0xFF42A5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          // child: Text(
                          //   userRole == "manager" ? "管" : "職",
                          //   style: const TextStyle(
                          //     fontSize: 11,
                          //     fontWeight: FontWeight.w700,
                          //     color: Colors.white,
                          //   ),
                          // ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 15),

            // 구분선
            Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey[300],
              indent: 16,
              endIndent: 16,
            ),
            const SizedBox(height: 15),

            // 待機リスト
            isExpanded
                ? _NavItem(
                    icon: Icons.list_alt_rounded,
                    label: '待機リスト',
                    selected: selectedIndex == 0,
                    onTap: () {
                      onItemTapped(0);
                      onToggle();
                    },
                  )
                : _NavIcon(
                    icon: Icons.list_alt_rounded,
                    selected: selectedIndex == 0,
                    label: '待機リスト',
                    onTap: () => onItemTapped(0),
                    isExpanded: isExpanded,
                  ),
            const SizedBox(height: 12),

            // メニュー管理
            isExpanded
                ? _NavItem(
                    icon: Icons.table_view_rounded,
                    label: 'メニュー管理',
                    selected: selectedIndex == 1,
                    onTap: () {
                      onItemTapped(1);
                      onToggle();
                    },
                  )
                : _NavIcon(
                    icon: Icons.table_view_rounded,
                    selected: selectedIndex == 1,
                    label: 'メニュー管理',
                    onTap: () => onItemTapped(1),
                    isExpanded: isExpanded,
                  ),
            const SizedBox(height: 12),

            const Spacer(),

            // 設定
            isExpanded
                ? _NavItem(
                    icon: Icons.settings_rounded,
                    label: '設定',
                    selected: selectedIndex == 3,
                    onTap: () {
                      onItemTapped(3);
                      onToggle();
                    },
                  )
                : _NavIcon(
                    icon: Icons.settings_rounded,
                    selected: selectedIndex == 3,
                    label: '設定',
                    onTap: () => onItemTapped(3),
                    isExpanded: isExpanded,
                  ),
            const SizedBox(height: 12),

            // 로그아웃 구분선
            Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey[300],
              indent: 16,
              endIndent: 16,
            ),
            const SizedBox(height: 12),

            // 로그아웃
            isExpanded
                ? _NavItem(
                    icon: Icons.logout_rounded,
                    label: 'ログアウト',
                    selected: false,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ログアウトしました')),
                      );
                    },
                  )
                : _NavIcon(
                    icon: Icons.logout_rounded,
                    selected: false,
                    label: 'ログアウト',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ログアウトしました')),
                      );
                    },
                    isExpanded: isExpanded,
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? Colors.grey[100] : Colors.transparent,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6F61).withOpacity(0.1), // 프로필과 동일
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFFEF5350) : Colors.grey[600],
              size: 26,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? const Color(0xFFEF5350) : Colors.grey[700],
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
  final bool selected;
  final VoidCallback? onTap;
  final bool isExpanded;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? Colors.grey[100] : Colors.transparent,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6F61).withOpacity(0.1), // 프로필과 동일
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            color: selected ? const Color(0xFFEF5350) : Colors.grey[600],
            size: 26,
          ),
        ),
      ),
    );
  }
}