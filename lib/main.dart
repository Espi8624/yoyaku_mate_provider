import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/navigation_bar.dart';
import 'package:yoyaku_mate_provider/services/provider_profile_service.dart';

import 'package:yoyaku_mate_provider/pages/menu_management_page/menu_management_page.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_page.dart';
import 'package:yoyaku_mate_provider/pages/sales_entry_page.dart';
import 'package:yoyaku_mate_provider/pages/sales_overview_page.dart';
import 'package:yoyaku_mate_provider/pages/shop_status_page.dart';
import 'package:yoyaku_mate_provider/pages/waiting_page/waiting_page.dart';
import 'package:yoyaku_mate_provider/pages/setting_page/setting_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isExpanded = false;

  // DB에서 가져올 값들
  String userName = '';
  String storeName = '';
  String userRole = '';
  bool isProfileLoading = true;

  // 실제 환경에서는 로그인 정보를 통해 아래 값들을 받아와야 합니다.
  final String userId = "685e89bf4104bb1e3dadab42";
  final String storeId = "store-001";
  final ProviderProfileService profileService = ProviderProfileService(baseUrl: "http://localhost:8080");

  static List<Widget> _pagesWithCallback(VoidCallback? onProfileChanged, ProviderProfileService profileService, String userId, String storeId) => [
    const WaitingPage(),
    const MenuManagementPage(),
    ProfilePage(onProfileChanged: onProfileChanged),
    const SettingPage(),
    const ShopStatusPage(),
    const SalesEntryPage(),
    const SalesOverviewPage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfileInfo();
  }

  Future<void> _fetchProfileInfo() async {
    setState(() { isProfileLoading = true; });
    try {
      final user = await profileService.fetchUserProfile(userId);
      final store = await profileService.fetchStoreProfile(storeId);
      setState(() {
        userName = user['user_name'] ?? '';
        userRole = user['role'] ?? '';
        storeName = store['store_name'] ?? '';
        isProfileLoading = false;
      });
    } catch (e) {
      setState(() { isProfileLoading = false; });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  // ProfilePage에서 이름/가게명 변경 시 네비게이션바 정보도 새로고침
  void refreshProfileInfo() {
    _fetchProfileInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Stack(
          children: [
            // 메인 컨텐츠: 항상 같은 위치와 크기
            Positioned.fill(
              left: 70,
              child: GestureDetector(
                onTap: () {
                  if (_isExpanded) {
                    setState(() {
                      _isExpanded = false;
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _pagesWithCallback(refreshProfileInfo, profileService, userId, storeId)[_selectedIndex],
                ),
              ),
            ),
            // 네비게이션 바: 확장 시 오른쪽으로 겹침
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              width: _isExpanded ? 270 : 60,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x99EDB6B0),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: isProfileLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SideNavigationBar(
                        isExpanded: _isExpanded,
                        selectedIndex: _selectedIndex,
                        onItemTapped: _onItemTapped,
                        onToggle: _toggleSidebar,
                        userName: userName,
                        storeName: storeName,
                        userRole: userRole,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
