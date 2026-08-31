import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/store_settings.dart';

class StoreSettingsService {
  final String baseUrl;
  StoreSettingsService({required this.baseUrl});

  // 認証 Token 取得
  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません。');
    }
    final String? token = await user.getIdToken();
    if (token == null) {
      throw Exception('認証トークンの取得に失敗しました。再ログインしてください。');
    }
    return token;
  }

  Future<StoreSettings> fetchStoreSettings(String storeId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/store_settings?store_id=$storeId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // サーバー応答が {status: success, data: {...}} 形式の場合
      return StoreSettings.fromJson(data['data']);
    } else {
      throw Exception('Failed to load store settings');
    }
  }

  Future<void> updateStoreSettings(StoreSettings settings) async {
    final token = await _getIdToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/store_settings?store_id=${settings.storeId}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(settings.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update store settings');
    }
  }
}
