import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/firebase_options.dart';
import 'package:yoyaku_mate_provider/pages/store_selection/store_selection_page.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/navigation_bar.dart';
import 'package:yoyaku_mate_provider/pages/menu_management_page/menu_management_screen.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen_viewmodel.dart';
import 'package:yoyaku_mate_provider/pages/staff_management_page/staff_management_screen.dart';
import 'package:yoyaku_mate_provider/pages/waiting_page/waiting_screen.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';
import 'package:yoyaku_mate_provider/services/store_settings_service.dart';
import 'package:yoyaku_mate_provider/pages/statistics_page/statistics_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:yoyaku_mate_provider/routes.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/navigation_bar_mobile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");

  // Crashlytics Configuration
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

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
              ProviderProfileService(baseUrl: dotenv.env['API_URL'] ?? ''),
        ),
        Provider<StoreSettingsService>(
          create: (_) =>
              StoreSettingsService(baseUrl: dotenv.env['API_URL'] ?? ''),
        ),
        StreamProvider<User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        ChangeNotifierProxyProvider<User?, ProfileScreenViewModel>(
          create: (context) => ProfileScreenViewModel(
            profileService: context.read<ProviderProfileService>(),
            settingsService: context.read<StoreSettingsService>(),
            userId: '',
            autoLoad: false,
          ),
          update: (context, user, previousViewModel) {
            if (previousViewModel == null) {
              return ProfileScreenViewModel(
                  profileService: context.read<ProviderProfileService>(),
                  settingsService: context.read<StoreSettingsService>(),
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
        builder: (context, child) {
          return Stack(
            children: [
              if (child != null) child,
              // ステータスバーの視認性向上のためのグラデーション
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
      final bool isManager = profileVM.userProfile?.role == 'manager';
      final storeId = profileVM.storeId;
      final List<Widget> pages = [
        WaitingScreen(storeId: storeId),
        MenuManagementScreen(storeId: storeId),
        StatisticsScreen(storeId: storeId),
        if (isManager) StaffManagementScreen(storeId: storeId),
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
                isManager: isManager,
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
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.assignment_ind_outlined,
                    size: 64,
                    color: AppColors.accentPrimary,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  '会員登録が完了していません',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'まだ会員登録が完了していません。\n下のボタンを押して会員登録を完了してください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
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
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '登録を完了する',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  child: const Text(
                    'ログアウト',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
