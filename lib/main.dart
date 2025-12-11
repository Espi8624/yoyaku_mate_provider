import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/firebase_options.dart';
import 'package:yoyaku_mate_provider/store_selection_view.dart';
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
              ProviderProfileService(baseUrl: 'https://saboten-server.fly.dev'),
        ),
        StreamProvider<User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        ChangeNotifierProxyProvider<User?, ProfileScreenViewModel>(
          create: (context) => ProfileScreenViewModel(
            profileService: context.read<ProviderProfileService>(),
            userId: '',
            autoLoad: false,
          ),
          update: (context, user, previousViewModel) {
            if (previousViewModel == null) {
              return ProfileScreenViewModel(
                  profileService: context.read<ProviderProfileService>(),
                  userId: '',
                  autoLoad: false);
            }

            final newUid = user?.uid ?? '';
            final oldUid = previousViewModel.firebaseUid;

            if (newUid == oldUid) {
              return previousViewModel;
            }

            previousViewModel.updateUser(newUid);
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

    if (profileVM.isProfileIncomplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 現在のパスが既にsignupならリダイレクトしない(ループ防止)
        // context.goだと確認できないが、GoRouterStateを取得するのが少し手間なので
        // 単純に遷移させる。routes.dart側で /signup にいる場合はリダイレクトしない制御があればベストだが
        // ここでは単純に遷移。
        try {
          // print("Attempting redirect to /signup?mode=resume");
          context.go('/signup?mode=resume');
        } catch (e) {
          // print("Redirect failed: $e");
        }
      });
      // 明示的なreturnを削除し、下の共通ローディング処理に任せる
      // return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // print("--- [HomeScreen] build 메서드 호출됨! ---");
    // print("  - 현재 보고 있는 ViewModel 해시코드: ${profileVM.hashCode}");
    // print("  - myStores 개수: ${profileVM.myStores.length}");

    // ローディング・エラー画面処理
    if (profileVM.isLoading && profileVM.userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profileVM.errorMessage != null && profileVM.userProfile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('データローディング失敗: ${profileVM.errorMessage}'),
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

    // ユーザーのプロフィールがない場合
    if (profileVM.userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isStoreSelected = profileVM.storeProfile != null;
    final bool hasStores = profileVM.myStores.isNotEmpty;

    // 選択された店舗がある場合、従来のメインダッシュボードUIを表示
    if (isStoreSelected) {
      final storeId = profileVM.storeId;
      final List<Widget> pages = [
        WaitingScreen(storeId: storeId),
        MenuManagementScreen(storeId: storeId),
        SettingScreen(storeId: storeId),
        const ProfileScreen(),
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
    } else if (hasStores) {
      return const StoreSelectionView();
    } else {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('所属された店舗がありません。管理者にお問い合わせください。'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // 登録プロセスを再開
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    try {
                      context.go('/signup?mode=resume');
                    } catch (e) {
                      // ignore
                    }
                  });
                },
                child: const Text('登録を再開する'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child:
                    const Text('ログアウト', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      );
    }
  }
}
