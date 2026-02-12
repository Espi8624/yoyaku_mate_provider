import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

// ログイン
Future<void> loginAndFetchUserInfo(String email, String password,
    Function(Map<String, dynamic>) onUserInfoLoaded) async {
  final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  final idToken = await userCredential.user!.getIdToken();
  final uid = userCredential.user!.uid;

  final baseUrl = dotenv.env['API_URL']!;

  // user_info 取得
  final response = await http.get(
    Uri.parse(
        '$baseUrl/api/provider_user/firebase_uid?uid=$uid&regenerate_token=true'),
    headers: {'Authorization': 'Bearer $idToken'},
  );
  if (response.statusCode == 200) {
    final userInfo = jsonDecode(response.body);

    // Save Login Token
    // Response is wrapped in { "status": "success", "data": { ... } }
    if (userInfo.containsKey('data') && userInfo['data'] is Map) {
      final data = userInfo['data'];
      if (data.containsKey('login_token')) {
        final token = data['login_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('login_token', token);
      }
    }

    onUserInfoLoaded(userInfo);
  } else {
    throw Exception('Failed to fetch user info');
  }
}
