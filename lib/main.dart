import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/navigation_bar.dart';
import 'package:yoyaku_mate_provider/pages/menu_management_page.dart';
import 'package:yoyaku_mate_provider/pages/profile_page.dart';
import 'package:yoyaku_mate_provider/pages/sales_entry_page.dart';
import 'package:yoyaku_mate_provider/pages/sales_overview_page.dart';
import 'package:yoyaku_mate_provider/pages/shop_status_page.dart';
import 'package:yoyaku_mate_provider/pages/waiting_page.dart';
import 'package:yoyaku_mate_provider/pages/setting_page.dart';

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
  bool _isExpanded = false; // 사이드바 확장 여부

  static const List<Widget> _pages = <Widget>[
    ShopStatusPage(),
    ProfilePage(),
    WaitingPage(),
    SalesEntryPage(),
    SalesOverviewPage(),
    MenuManagementPage(),
    SettingPage(),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text(
      //     'Yoyaku Mate',
      //     style: TextStyle(
      //       fontWeight: FontWeight.bold,
      //     ),
      //   ),
      // ),
      body: Stack(
        children: [
          // 메인 컨텐츠: 항상 같은 위치와 크기
          Positioned.fill(
            left: 80, // 네비게이션 바 최소 너비만큼 띄움
            child: _pages[_selectedIndex],
          ),
          // 네비게이션 바: 확장 시 오른쪽으로 겹침
          Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            width: _isExpanded ? 270 : 60,
            child: SideNavigationBar(
              isExpanded: _isExpanded,
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
              onToggle: _toggleSidebar,
            ),
          ),
        ],
      ),
    );
  }
}
