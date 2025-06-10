import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/widget/personal_profile_tab.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/widget/store_profile_tab.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 사용자 권한 (실제로는 로그인 정보에서 가져와야 함)
  String userRole = "manager"; // "사장" 또는 "직원" 등

  @override
  void initState() {
    super.initState();
    // 권한에 따라 탭 개수 결정 (사장이면 2개, 직원이면 1개)
    _tabController = TabController(
      length: userRole == "manager" ? 2 : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            const Padding(
              padding: EdgeInsets.all(24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "プロフィール設定",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
              ),
            ),

            // 탭 바 (사장 권한일 때만 표시)
            if (userRole == "manager")
              Container(
                height: 34,
                width: 190,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: const Color(0xFF263238),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6F61).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[700],
                  labelPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                  tabs: const [
                    Tab(text: '個人'),
                    Tab(text: '店舗'),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // 탭 뷰
            Expanded(
              child: userRole == "manager"
                  ? TabBarView(
                      controller: _tabController,
                      children: const [
                        PersonalProfileTab(),
                        StoreProfileTab(),
                      ],
                    )
                  : const PersonalProfileTab(),
            ),
          ],
        ),
      ),
    );
  }
}
