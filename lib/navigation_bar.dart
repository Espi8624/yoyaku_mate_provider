import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/custom_snack_bar.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class SideNavigationBar extends StatelessWidget {
  final bool isExpanded;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onToggle;
  final String userName;
  final String storeName;
  final String userRole; // 管理者 or 職員
  final VoidCallback? onLogout;

  const SideNavigationBar({
    super.key,
    required this.isExpanded,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onToggle,
    required this.userName,
    required this.storeName,
    required this.userRole,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: isExpanded ? 280 : 80,
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.mainAccent.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: IconButton(
                  icon: Icon(
                    isExpanded ? Icons.close : Icons.menu_rounded,
                    color: AppColors.mainAccent,
                    size: 28,
                  ),
                  onPressed: onToggle,
                  splashRadius: 20,
                ),
              ),
            ),
            const SizedBox(height: 15),

            // プロフィール区画
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
                              color: AppColors.mainAccent.withOpacity(0.2),
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
                          color: AppColors.mainAccent.withOpacity(0.2),
                          child: const Icon(Icons.person,
                              size: 30, color: AppColors.background),
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
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: userRole == "manager"
                                        ? AppColors.secondaryAccent
                                        : AppColors.mainAccent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    userRole == "manager" ? "管理者" : "職員",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              storeName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
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
            ]
            else ...[
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
                              color: AppColors.mainAccent.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Container(
                      width: 50, // アイコンの直径
                      height: 50, // アイコンの直径
                      decoration: BoxDecoration(
                        // プロフィールアイコン背景色
                        color: AppColors.mainAccent.withOpacity(0.2),
                        shape: BoxShape.circle,
                        // リング色
                        border: Border.all(
                          color: userRole == "manager"
                              ? AppColors.secondaryAccent // 管理者
                              : AppColors.mainAccent, // 職員
                          width: 5.0, // リング幅
                        ),
                      ),
                      // アイコン設定
                      child: const Icon(
                        Icons.person,
                        size: 24,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 15),

            const Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.divider,
              indent: 16,
              endIndent: 16,
            ),
            const SizedBox(height: 15),

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

            const Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.divider,
              indent: 16,
              endIndent: 16,
            ),
            const SizedBox(height: 12),

            isExpanded
                ? _NavItem(
                    icon: Icons.logout_rounded,
                    label: 'ログアウト',
                    selected: false,
                    onTap: () {
                      if (onLogout != null) {
                        onLogout!();
                      } else {
                        CustomSnackBar.show(
                          context,
                          message: 'ログアウトしました',
                          status: SnackBarStatus.info,
                        );
                      }
                    },
                  )
                : _NavIcon(
                    icon: Icons.logout_rounded,
                    selected: false,
                    label: 'ログアウト',
                    onTap: () {
                      if (onLogout != null) {
                        onLogout!();
                      } else {
                        CustomSnackBar.show(
                          context,
                          message: 'ログアウトしました',
                          status: SnackBarStatus.info,
                        );
                      }
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
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.mainAccent.withOpacity(0.2),
                    blurRadius: 16,
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
              color: selected ? AppColors.mainAccent : AppColors.textSecondary,
              size: 26,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color:
                    selected ? AppColors.mainAccent : AppColors.textSecondary,
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
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.mainAccent.withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            color: selected ? AppColors.mainAccent : AppColors.textSecondary,
            size: 26,
          ),
        ),
      ),
    );
  }
}
