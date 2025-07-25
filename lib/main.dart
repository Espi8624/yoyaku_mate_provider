import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/firebase_options.dart';
import 'package:yoyaku_mate_provider/navigation_bar.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';
import 'package:yoyaku_mate_provider/login_page.dart';

import 'package:yoyaku_mate_provider/pages/menu_management_page/menu_management_screen.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_page.dart';
import 'package:yoyaku_mate_provider/pages/sales_entry_page.dart';
import 'package:yoyaku_mate_provider/pages/sales_overview_page.dart';
import 'package:yoyaku_mate_provider/pages/shop_status_page.dart';
import 'package:yoyaku_mate_provider/pages/waiting_page/waiting_page.dart';
import 'package:yoyaku_mate_provider/pages/setting_page/setting_page.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;

  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            home: _isLoggedIn ? const HomeScreen() : LoginPage(onLoginSuccess: _onLoginSuccess),
          );
        }
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Firebase 初期化エラー:\n	${snapshot.error}')),
            ),
          );
        }
        return const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
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

  final ProviderProfileService profileService = ProviderProfileService(baseUrl: "http://localhost:8080");

  List<Widget> _pagesWithCallback(VoidCallback? onProfileChanged, ProviderProfileService profileService, String userId, String userRole, String storeId) => [
    const WaitingPage(),
    MenuManagementScreen(storeId: storeId),
    ProfilePage(
      userId: userId,
      userRole: userRole,
      storeId: storeId,
      onProfileChanged: onProfileChanged,
    ),
    SettingPage(storeId: storeId),
    const ShopStatusPage(),
    const SalesEntryPage(),
    const SalesOverviewPage(),
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
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.userId ?? '';
    final userRole = userProvider.userRole ?? '';
    final storeId = userProvider.storeInfo?['data']['store_id'] ?? '';
    final storeName = userProvider.storeInfo?['data']['store_name'] ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Stack(
          children: [
            // メインコンテンツ区画
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
                  child: _pagesWithCallback(null, profileService, userId, userRole, storeId)[_selectedIndex],
                ),
              ),
            ),
            // ナビゲーションバー区画
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
                child: SideNavigationBar(
                  isExpanded: _isExpanded,
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                  onToggle: _toggleSidebar,
                  userName: userProvider.userName ?? '',
                  storeName: storeName ?? '',
                  userRole: userRole,
                  onLogout: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('本当にログアウトしますか？', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            IconButton(
                              icon: const Icon(Icons.close, color: Color(0xFF263238)),
                              onPressed: () => Navigator.pop(context, false),
                              splashRadius: 20,
                              tooltip: 'キャンセル',
                            ),
                          ],
                        ),
                        actionsAlignment: MainAxisAlignment.center,
                        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        actions: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6F61),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('ログアウト'),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (result == true) {
                      Provider.of<UserProvider>(context, listen: false).clear();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MyApp()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
