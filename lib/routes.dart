import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yoyaku_mate_provider/login_page.dart';
import 'package:yoyaku_mate_provider/main.dart';
import 'package:yoyaku_mate_provider/pages/sign_up_prompt_page.dart';
// import 'package:yoyaku_mate_provider/sign_up_complete_page.dart';
import 'package:yoyaku_mate_provider/sign_up_page.dart';

bool _isSignUpInProgress = false;

void setSignUpInProgress(bool value) {
  _isSignUpInProgress = value;
}

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
final GoRouter router = GoRouter(
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
        final mode = state.uri.queryParameters['mode'];

        // 抽出したmode値をSignUpPageのコンストラクタに渡す
        return SignUpPage(mode: mode);
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
      path: '/signup-prompt',
      builder: (context, state) => const SignUpPromptPage(),
    ),
  ],

  // 自動でページ移動
  redirect: (BuildContext context, GoRouterState state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final location = state.matchedLocation;

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
