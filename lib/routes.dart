import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yoyaku_mate_provider/login_page.dart';
import 'package:yoyaku_mate_provider/main.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/sign_up_page.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/sign_up_viewmodel.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/sign_up_prompt_page.dart';
import 'package:yoyaku_mate_provider/pages/store_selection/add_store_page.dart';
import 'package:yoyaku_mate_provider/verify_email_page.dart';

bool _isSignUpInProgress = false;

void setSignUpInProgress(bool value) {
  _isSignUpInProgress = value;
}

// 最後に有効だったパスを保持（Deep Link復帰用）
String? _lastValidLocation;

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<User?> _authSubscription;

  GoRouterRefreshStream() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      // SignUp中でない場合のみnotifyListeners呼出
      if (!_isSignUpInProgress) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}

// Router設定Object生成
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  routerNeglect: true,
  refreshListenable: GoRouterRefreshStream(),
  // 初期経路
  initialLocation: '/',

  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const HomeScreen();
      },
    ),
    // ログインページ
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    // 会員加入ページ
    GoRoute(
      path: '/signup',
      builder: (context, state) {
        // UrlからQuery Parametersを抽出
        return ChangeNotifierProvider(
          create: (_) => SignUpViewModel(),
          child: const SignUpPage(),
        );
      },
    ),
    // 会員加入完了ページ
    // GoRoute(
    //   path: '/signup/complete',
    //   builder: (context, state) => const SignUpCompletePage(),
    // ),
    // GoRoute(
    //   path: '/complete',
    //   builder: (context, state) => const SignUpCompletePage(),
    // ),
    GoRoute(
      path: '/add-store',
      builder: (context, state) => const AddStorePage(),
    ),
    GoRoute(
      path: '/signup-prompt',
      builder: (context, state) => const SignUpPromptPage(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) => const VerifyEmailPage(),
    ),
  ],

  // 自動でページ移動
  redirect: (BuildContext context, GoRouterState state) {
    final currentUser = FirebaseAuth.instance.currentUser;
    // メール認証が完了していない場合はログアウト状態として扱う
    final loggedIn = currentUser != null && currentUser.emailVerified;
    final location = state.matchedLocation;
    final uri = state.uri;

    // Firebase Auth Deep Link (reCAPTCHA/Phone Auth) 対策
    // app-1-... というスキームやURLが渡された場合、直前の有効なパスに戻す
    if (uri.scheme.startsWith('app-1-') ||
        uri.toString().startsWith('app-1-')) {
      // 直前のパスがあればそこへ、なければログイン画面へ
      // (通常は _isSignUpInProgress でガードされるが、念のため)
      return _lastValidLocation ?? '/login';
    }

    // 有効な通常パスであれば記録しておく
    if (!location.startsWith('app-1-')) {
      _lastValidLocation = state.uri.toString();
    }

    if (_isSignUpInProgress) {
      return null;
    }

    // SignUpPageに対する例外処理
    if (location == '/signup') {
      return null;
    }

    // if (location == '/complete') {
    //   return '/signup/complete';
    // }

    // ログアウト状態の規則
    final onAuthFlow = location == '/login' || location == '/signup-prompt';
    // || location == '/signup/complete';
    if (!loggedIn && !onAuthFlow) {
      return '/login';
    }

    // ログイン状態の規則
    if (loggedIn && location == '/login') {
      return '/';
    }

    return null;
  },

  // エラーページ定義
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.error}'),
    ),
  ),
);

// // FirebaseAuthのStreamをGoRouterのrefreshListenableに変換
// class GoRouterRefreshStream extends ChangeNotifier {
//   GoRouterRefreshStream(Stream<dynamic> stream) {
//     notifyListeners();
//     _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
//   }
//   late final StreamSubscription<dynamic> _subscription;

//   @override
//   void dispose() {
//     _subscription.cancel();
//     super.dispose();
//   }
// }
