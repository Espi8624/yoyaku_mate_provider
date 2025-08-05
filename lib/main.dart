import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/firebase_options.dart';
import 'package:yoyaku_mate_provider/login_page.dart';
import 'package:yoyaku_mate_provider/navigation_bar.dart';
import 'package:yoyaku_mate_provider/pages/menu_management_page/menu_management_screen.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_page.dart';
import 'package:yoyaku_mate_provider/pages/sales_entry_page.dart';
import 'package:yoyaku_mate_provider/pages/sales_overview_page.dart';
import 'package:yoyaku_mate_provider/pages/setting_page/setting_page.dart';
import 'package:yoyaku_mate_provider/pages/shop_status_page.dart';
import 'package:yoyaku_mate_provider/pages/waiting_page/waiting_page.dart';
import 'package:yoyaku_mate_provider/user_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yoyaku Mate Provider',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        canvasColor: AppColors.cardBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentPrimary,
          background: AppColors.background,
        ),
        useMaterial3: true, 
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeScreenDataLoader();
        }
        return const LoginPage();
      },
    );
  }
}

class HomeScreenDataLoader extends StatelessWidget {
  const HomeScreenDataLoader({super.key});

  Future<void> _loadUserData(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User is not logged in.");

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.userId != null) return;

    final idToken = await user.getIdToken();
    final userResponse = await http.get(
      Uri.parse(
          'http://localhost:8080/api/provider_user/firebase_uid?uid=${user.uid}'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (userResponse.statusCode != 200) {
      throw Exception('Failed to fetch user info: ${userResponse.body}');
    }
    final userInfo = jsonDecode(userResponse.body);
    userProvider.setUserInfo(userInfo);

    final userIdFromProvider = userProvider.userId;
    if (userIdFromProvider != null) {
      final storeResponse = await http.get(
        Uri.parse(
            'http://localhost:8080/api/provider_store?user_id=$userIdFromProvider'),
      );
      if (storeResponse.statusCode == 200 && storeResponse.body.isNotEmpty) {
        final storeInfo = jsonDecode(storeResponse.body);
        userProvider.setStoreInfo(storeInfo);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadUserData(context),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('データローディング失敗: ${snapshot.error}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text('ログアウト'),
                  )
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return const HomeScreen();
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.userId == null) {
      return const Scaffold(body: Center(child: Text("ユーザー情報が見つかりません")));
    }

    final userId = userProvider.userId!;
    final userRole = userProvider.userRole ?? '';
    final storeData = userProvider.storeInfo?['data'];
    String storeId = '';
    String storeName = '';

    if (storeData is Map) {
      storeId = storeData['store_id']?.toString() ?? '';
      storeName = storeData['store_name']?.toString() ?? '';
    }

    final List<Widget> pages = [
      WaitingPage(storeId: storeId),
      MenuManagementScreen(storeId: storeId),
      ProfilePage(userId: userId, userRole: userRole, storeId: storeId),
      SettingPage(storeId: storeId),
      const ShopStatusPage(),
      const SalesEntryPage(),
      const SalesOverviewPage(),
    ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            SideNavigationBar(
              isExpanded: _isExpanded,
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
              onToggle: _toggleSidebar,
              userName: userProvider.userName ?? '',
              storeName: storeName,
              userRole: userRole,
              onLogout: () async {
                userProvider.clear();
                await FirebaseAuth.instance.signOut();
              },
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_isExpanded) _toggleSidebar();
                },
                child: Container( 
                  margin: const EdgeInsets.only(left: 12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: pages[_selectedIndex],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
