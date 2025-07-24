import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/firebase_options.dart';
import 'package:yoyaku_mate_provider/navigation_bar.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';
import 'package:yoyaku_mate_provider/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth 임포트 추가

import 'package:yoyaku_mate_provider/pages/menu_management_page/menu_management_page.dart';
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
  // runApp 이전에 Firebase를 초기화하여 앱 로드 시 한 번만 초기화되도록 합니다.
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

class MyApp extends StatelessWidget { // StatefulWidget에서 StatelessWidget으로 변경
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth.instance.authStateChanges() 스트림을 사용하여
    // Firebase 인증 상태 변화를 실시간으로 감지하고 UI를 업데이트합니다.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase 연결 상태가 대기 중일 때 로딩 인디케이터를 표시합니다.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
<<<<<<< HEAD
              body: Center(child: Text('Firebase 初期化エラー:\n	${snapshot.error}')),
=======
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // 스냅샷에 오류가 있다면 오류 메시지를 표시합니다.
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('認証エラー:\n ${snapshot.error}')),
            ),
          );
        }

        // 사용자가 로그인되어 있는지 확인합니다.
        // snapshot.hasData는 데이터가 있는지, snapshot.data != null은 데이터가 null이 아님을 의미합니다.
        if (snapshot.hasData && snapshot.data != null) {
          // Firebase에 로그인된 유저가 있다면 HomeScreen을 표시합니다.
          // UserProvider에 사용자 정보를 로드하는 로직은 LoginPage에서 처리되므로,
          // 여기서는 단순히 HomeScreen으로 이동합니다.
          return const MaterialApp(
            home: HomeScreen(),
          );
        } else {
          // Firebase에 로그인된 유저가 없다면 LoginPage를 표시합니다.
          return MaterialApp(
            home: LoginPage(
              // LoginPage에서 로그인 성공 시 이 콜백이 호출되지만,
              // StreamBuilder가 Firebase 인증 상태 변화를 감지하여
              // 자동으로 HomeScreen으로 전환해줄 것이므로 추가적인 Navigator 로직은 필요 없습니다.
              onLoginSuccess: () {
                // 이 콜백은 필요에 따라 비워두거나, 특정 로깅 등을 수행할 수 있습니다.
              },
>>>>>>> ffc7e7cd483f683643ac3c17b2a68c958ec23eac
            ),
          );
        }
      },
    );
  }
}

// HomeScreen 이하는 기존과 동일하게 유지됩니다.
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
    MenuManagementPage(storeId: storeId),
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

    // 방어 로직: 만약 UserProvider에 사용자 정보가 아직 로드되지 않았다면 (예: 앱 재시작 시),
    // 다시 로그인 페이지로 보내어 정보를 다시 로드하도록 유도합니다.
    // 이는 StreamBuilder가 로그인 상태를 감지한 후 UserProvider의 정보 로딩이 비동기적으로
    // 완료되기 전 잠시 발생하는 빈 상태를 처리하기 위함입니다.
    if (userId.isEmpty || userRole.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // StreamBuilder가 이미 로그인 상태를 감지했음에도 불구하고 UserProvider의 데이터가 비어있다면
          // 이는 백엔드 데이터 로딩 이슈일 수 있으므로, 재로그인을 유도합니다.
          // 이 경우, 사용자가 로그인을 하면 UserProvider에 정보가 다시 로드될 것입니다.
          if (FirebaseAuth.instance.currentUser != null) { // Firebase에는 로그인 되어있는데 프로바이더에 정보가 없으면
            // 이미 로그인되어있으니 main.dart의 StreamBuilder가 다시 LoginPage로 보내진 않을 것.
            // 따라서 이곳에서 강제로 LoginPage로 보내어 정보 재로드 시도
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => LoginPage(onLoginSuccess: () {})),
              (route) => false,
            );
          }
        });
        // 정보를 로드하는 동안 로딩 인디케이터를 보여줍니다.
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }


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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                  storeName: storeName, // Null 처리 이미 되어있음
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
                      // 1. Firebase에서 로그아웃
                      await FirebaseAuth.instance.signOut();
                      // 2. UserProvider의 모든 사용자 정보 초기화
                      Provider.of<UserProvider>(context, listen: false).clear();
                      // FirebaseAuth.instance.signOut()가 호출되면
                      // MyApp의 StreamBuilder가 인증 상태 변경을 감지하여
                      // 자동으로 LoginPage로 전환될 것이므로 별도의 pushAndRemoveUntil은 필요 없습니다.
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