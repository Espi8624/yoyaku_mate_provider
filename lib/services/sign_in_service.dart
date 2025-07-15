import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 로그인 함수 예시
Future<void> loginAndFetchUserInfo(String email, String password, Function(Map<String, dynamic>) onUserInfoLoaded) async {
  final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  final idToken = await userCredential.user!.getIdToken();
  final uid = userCredential.user!.uid;

  // user_info 조회 (아래 2번 참고)
  final response = await http.get(
    Uri.parse('http://localhost:8080/api/provider_user/firebase_uid?uid=$uid'),
    headers: {'Authorization': 'Bearer $idToken'},
  );
  if (response.statusCode == 200) {
    final userInfo = jsonDecode(response.body);
    onUserInfoLoaded(userInfo);
  } else {
    throw Exception('Failed to fetch user info');
  }
}