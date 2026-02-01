import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ログイン
Future<void> loginAndFetchUserInfo(String email, String password,
    Function(Map<String, dynamic>) onUserInfoLoaded) async {
  final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  final idToken = await userCredential.user!.getIdToken();
  final uid = userCredential.user!.uid;

  // user_info 取得
  final response = await http.get(
    Uri.parse(
        'https://saboten-server.fly.dev/api/provider_user/firebase_uid?uid=$uid'),
    headers: {'Authorization': 'Bearer $idToken'},
  );
  if (response.statusCode == 200) {
    final userInfo = jsonDecode(response.body);

    // Save Login Token
    if (userInfo.containsKey('login_token')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('login_token', userInfo['login_token']);
    }

    onUserInfoLoaded(userInfo);
  } else {
    throw Exception('Failed to fetch user info');
  }
}
