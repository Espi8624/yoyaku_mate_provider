import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yoyaku_mate_provider/login_page.dart';
import 'package:yoyaku_mate_provider/main.dart';
import 'package:yoyaku_mate_provider/sign_up_complete_page.dart';
import 'package:yoyaku_mate_provider/sign_up_page.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<User?> _authSubscription;

  GoRouterRefreshStream() {
    _authSubscription = FirebaseAuth.instance
        .authStateChanges()
        .listen((_) => notifyListeners());
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

  // 3. URL定義
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
    GoRoute(
      path: '/signup/complete',
      builder: (context, state) => const SignUpCompletePage(),
    ),
    GoRoute(
      path: '/complete',
      builder: (context, state) => const SignUpCompletePage(),
    ),
  ],

  // 自動でページ移動
  redirect: (BuildContext context, GoRouterState state) {
    final String location = state.matchedLocation;
    final String fullUri = state.uri.toString();
    print(
        'GoRouter redirecting, matched location: $location, fullUri: $fullUri');

    if (location == '/complete' || location == '/signup/complete') {
      print('Deep link detected. Allowing navigation to /signup/complete.');
      if (location != '/signup/complete') {
        return '/signup/complete';
      }
      return null;
    }

    // デイップリンクでない場合のみ、既存のログイン状態検査を実行
    final bool loggedIn = FirebaseAuth.instance.currentUser != null;
    final bool isGoingToAuthPage =
        location == '/login' || location == '/signup';
    final bool isAddingStore = fullUri.contains('mode=add_store');

    if (!loggedIn && !isGoingToAuthPage) {
      return '/login';
    }

    if (loggedIn && isGoingToAuthPage && !isAddingStore) {
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
