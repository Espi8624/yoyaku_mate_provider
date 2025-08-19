import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/firebase_options.dart';
import 'package:yoyaku_mate_provider/login_page.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/navigation_bar.dart';
import 'package:yoyaku_mate_provider/pages/menu_management_page/menu_management_screen.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen_viewmodel.dart';
import 'package:yoyaku_mate_provider/pages/setting_page/setting_screen.dart';
import 'package:yoyaku_mate_provider/pages/waiting_page/waiting_screen.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
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
          return ProfileViewModelProvider(user: snapshot.data!);
        }
        return const LoginPage();
      },
    );
  }
}

// ProfileViewModel を生成し、下位 Widget ツリーに提供
// 既存　HomeScreenDataLoader & UserProvider を対応
class ProfileViewModelProvider extends StatelessWidget {
  final User user;
  const ProfileViewModelProvider({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileScreenViewModel(
        profileService:
            ProviderProfileService(baseUrl: "http://localhost:8080"),
        userId: user.uid, // Firebase UID を使用者 ID で使用
      ),
      child: const HomeScreen(),
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

  @override
  void initState() {
    super.initState();
    // Widget がビルドされた直後に ViewModel のデータローディングメソッドを呼出
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileScreenViewModel>().loadProfiles();
    });
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

  @override
  Widget build(BuildContext context) {
    // final userProvider = Provider.of<UserProvider>(context, listen: false);
    final profileVM = context.watch<ProfileScreenViewModel>();

    if (profileVM.isLoading && profileVM.userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!profileVM.isLoading && profileVM.userProfile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('データローディング失敗: ${profileVM.errorMessage ?? "不明なエラー"}'),
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

    // データローディング成功
    final storeId = profileVM.storeId;

    final List<Widget> pages = [
      WaitingScreen(storeId: storeId),
      MenuManagementScreen(storeId: storeId),
      const ProfileScreen(),
      SettingScreen(storeId: storeId),
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
              onLogout: () async {
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
