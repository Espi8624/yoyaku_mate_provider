import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yoyaku_mate_provider/login_page.dart';
import 'package:yoyaku_mate_provider/main.dart'; // AuthWrapper, HomeScreen 등을 위해 import
import 'package:yoyaku_mate_provider/sign_up_complete_page.dart';
import 'package:yoyaku_mate_provider/sign_up_page.dart'; // SignUpPage import

// Router設定Object生成
final GoRouter router = GoRouter(
  refreshListenable:
      GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
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
      builder: (context, state) => const SignUpPage(),
    ),
    // 会員加入完了ページ
    GoRoute(
      path: '/signup/complete',
      builder: (context, state) => const SignUpCompletePage(),
    ),
  ],

  // 自動でページ移動
  redirect: (BuildContext context, GoRouterState state) {
    // 現在ログインステータス確認
    final bool loggedIn = FirebaseAuth.instance.currentUser != null;
    // ユーザーが移動しようとしている経路がログイン関連ページなのか確認
    final bool isLoggingIn =
        state.matchedLocation == '/login' || state.matchedLocation == '/signup';

    // ログアウト状態で、保護されたページ('/')に行こうとする
    if (!loggedIn && !isLoggingIn) {
      // ログインページへ移動
      return '/login';
    }

    // ログイン状態で、ログイン/会員加入ページに移動しようとする
    if (loggedIn && isLoggingIn) {
      // メインページへ移動
      return '/';
    }

    // そのほか全ての場合許容(nullを返却したら元の経路へ移動)
    return null;
  },

  // エラーページ定義
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.error}'),
    ),
  ),
);

// FirebaseAuthのStreamをGoRouterのrefreshListenableに変換
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
