import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderScope, ConsumerStatefulWidget, ConsumerState, AsyncValueX;
import 'package:go_router/go_router.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/firebase_options.dart';
import 'package:yoyaku_mate_provider/pages/store_selection/store_selection_page.dart';
import 'package:yoyaku_mate_provider/providers/session_providers.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/navigation_bar.dart';
import 'package:yoyaku_mate_provider/pages/menu_management_page/menu_management_screen.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen.dart';
import 'package:yoyaku_mate_provider/pages/staff_management_page/staff_management_screen.dart';
import 'package:yoyaku_mate_provider/pages/waiting_page/waiting_screen.dart';
import 'package:yoyaku_mate_provider/pages/statistics_page/statistics_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:yoyaku_mate_provider/routes.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/navigation_bar_mobile.dart';
import 'package:yoyaku_mate_provider/services/session_service.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/session_revoked_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kReleaseMode) {
    await dotenv.load(fileName: ".env.production");
  } else {
    await dotenv.load(fileName: ".env.development");
  }

  // Crashlytics Configuration
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // ProviderScope: Riverpod 상태관리 루트 스코프
  // (기존 provider 패키지 기반 MultiProvider 트리는 MyApp 내부에 그대로 유지 -
  //  페이지 단위로 순차 마이그레이션하는 동안 두 트리가 공존한다)
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ユーザー/店舗セッション状態・統計データはRiverpodへ全面移行済みのため
    // provider パッケージのMultiProviderは不要になった
    return MaterialApp.router(
      routerConfig: router, // GoRouter設定を使用
      title: 'ルスイ店舗管理',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        canvasColor: AppColors.cardBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentPrimary,
          background: AppColors.background,
        ),
        useMaterial3: true,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.accentPrimary,
          selectionColor: AppColors.accentPrimary,
          selectionHandleColor: AppColors.accentPrimary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.accentPrimary, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border, width: 1.0),
          ),
          floatingLabelStyle: const TextStyle(color: AppColors.accentPrimary),
        ),
      ),
      builder: (context, child) {
        // - 他端末ログインによるセッション無効化は、どの画面を開いていても
        //   同じ挙動になるようアプリのルートで1箇所だけ購読する
        return SessionRevokedListener(
          child: Stack(
            children: [
              if (child != null) child,
              // ステータスバーの視認性向上のためのグラデーション
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
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
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    final userProfileAsync = ref.watch(userProfileProvider);

    // ユーザーがまだ登録されていない場合 (サインアップ未完了) はサインアップへ誘導
    if (userProfileAsync.hasError &&
        userProfileAsync.error is ProfileNotFoundException) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 現在のパスが既にsignupならリダイレクトしない(ループ防止)
        // context.goだと確認できないが、GoRouterStateを取得するのが少し手間なので
        // 単純に遷移させる。routes.dart側で /signup にいる場合はリダイレクトしない制御があればベストだが
        // ここでは単純に遷移。
        if (!context.mounted) return;
        try {
          context.go('/signup?mode=resume');
        } catch (e) {
          // print("Redirect failed: $e");
        }
      });
      return const Scaffold(
          body: Center(
              child:
                  CircularProgressIndicator(color: AppColors.accentPrimary)));
    }

    // ローディング・エラー画面処理
    if (userProfileAsync.isLoading && !userProfileAsync.hasValue) {
      return const Scaffold(
          body: Center(
              child:
                  CircularProgressIndicator(color: AppColors.accentPrimary)));
    }

    if (userProfileAsync.hasError && !userProfileAsync.hasValue) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('データローディング失敗: ${userProfileAsync.error}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // - サーバー側の端末セッションも破棄してから認証を切る
                  await SessionService.instance.clear();
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
    final userProfile = userProfileAsync.valueOrNull;
    if (userProfile == null) {
      return const Scaffold(
          body: Center(
              child:
                  CircularProgressIndicator(color: AppColors.accentPrimary)));
    }

    final selectedStore = ref.watch(selectedStoreProfileProvider);
    final bool isStoreSelected = selectedStore != null;

    // 選択された店舗がある場合、従来のメインダッシュボードUIを表示
    if (isStoreSelected) {
      final storeId = selectedStore.id;
      final List<Widget> pages = [
        WaitingScreen(storeId: storeId),
        MenuManagementScreen(storeId: storeId),
        StatisticsScreen(storeId: storeId),
        // スタッフメニューはManager/Staff共通で表示
        StaffManagementScreen(storeId: storeId),
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
              // Remove outer SafeArea to control bottom padding manually
              body: Row(
                children: [
                  // Sidebar: Use standard SafeArea (spaces out both sides if needed)
                  SafeArea(
                    right: false,
                    bottom: false,
                    left: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                      child: SideNavigationBar(
                        isExpanded: _isExpanded,
                        selectedIndex: _selectedIndex,
                        onItemTapped: _onItemTapped,
                        onToggle: _toggleSidebar,
                        onLogout: () async {
                          // - サーバー側の端末セッションも破棄してから認証を切る
                          await SessionService.instance.clear();
                          await FirebaseAuth.instance.signOut();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 4.0,
                  ),
                  // Content: Respect bottom safe area
                  Expanded(
                    child: SafeArea(
                      left: false,
                      bottom: false,
                      // Content needs bottom safe area
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
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
                    ),
                  ),
                ],
              ),
            );
          }
        },
      );
    } else {
      // 店舗が選択されていない場合、または店舗がない場合は店舗選択画面を表示
      // Refactor: Sign-Upフロー変更により、店舗がない場合もここに到達して「新規作成」を促す
      return const StoreSelectionView();
    }
  }
}
