import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/firebase_options.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/navigation_bar.dart';
import 'package:yoyaku_mate_provider/pages/menu_management_page/menu_management_screen.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen_viewmodel.dart';
import 'package:yoyaku_mate_provider/pages/setting_page/setting_screen.dart';
import 'package:yoyaku_mate_provider/pages/waiting_page/waiting_screen.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';

import 'package:yoyaku_mate_provider/routes.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/navigation_bar_mobile.dart';

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
    return MultiProvider(
      providers: [
        Provider<ProviderProfileService>(
          create: (_) =>
              ProviderProfileService(baseUrl: "http://10.0.2.2:8080"),
        ),
        StreamProvider<User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        ChangeNotifierProxyProvider<User?, ProfileScreenViewModel>(
          create: (context) => ProfileScreenViewModel(
            profileService: context.read<ProviderProfileService>(),
            userId: '',
          ),
          update: (context, user, previousViewModel) {
            final newUid = user?.uid ?? '';
            // UIDが変更された時のみ新しいViewModelを生成し、データ損失防止
            if (previousViewModel == null ||
                previousViewModel.firebaseUid != newUid) {
              return ProfileScreenViewModel(
                profileService: context.read<ProviderProfileService>(),
                userId: newUid,
              );
            }
            return previousViewModel;
          },
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router, // GoRouter設定を使用
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
      ),
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
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      // ログアウト実行
      FirebaseAuth.instance.signOut();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
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

    if (profileVM.userProfile == null &&
        !profileVM.isLoading &&
        profileVM.errorMessage == null &&
        profileVM.firebaseUid.isNotEmpty) {
      // プレイム終了直後に実行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // ViewModelを取り戻し、loadProfiles()を呼び出す
        context.read<ProfileScreenViewModel>().loadProfiles();
      });
    }

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
      Container(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // mobile/ desktopを区分する基準点を設定
        const double mobileBreakpoint = 700;

        // 設定値より幅が狭い場合mobileレイアウトを表示
        if (constraints.maxWidth < mobileBreakpoint) {
          // mobile layout
          return Scaffold(
            body: pages[_selectedIndex],
            bottomNavigationBar: NavigationBarMobile(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          );
        } else {
          // desktop layout
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(8.0),
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
                  const SizedBox(
                    width: 12.0,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_isExpanded) _toggleSidebar();
                      },
                      child: Container(
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
      },
    );
  }
}
