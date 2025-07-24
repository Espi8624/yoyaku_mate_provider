import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/provider_profile.dart';

class ProviderProfileService {
  final String baseUrl;
  ProviderProfileService({required this.baseUrl});

  // 使用者プロファイル取得
  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/provider_user?user_id=$userId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  // 使用者プロファイル更新
  Future<void> updateUserProfile(String userId, Map<String, dynamic> update) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/provider_user?user_id=$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(update),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user profile');
    }
  }

  // 店舗プロファイル取得
  Future<Map<String, dynamic>> fetchStoreProfile(String storeId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/provider_store?store_id=$storeId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load store profile');
    }
  }

  // 店舗プロファイル更新
  Future<void> updateStoreProfile(String storeId, Map<String, dynamic> update) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/provider_store?store_id=$storeId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(update),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update store profile');
    }
  }

  // 会員加入
  Future<Map<String, dynamic>> signUp(ProviderProfile profile) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profile.toJson()),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to sign up: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  // 店舗存在確認
  Future<bool> checkStoreExists(String storeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/store/$storeId/exists'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] as bool;
      } else {
        throw Exception('Failed to check store existence: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to check store existence: $e');
    }
  }

  // メール中腹チェック
  Future<bool> checkEmailAvailability(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/check-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['available'];
    } else {
      throw Exception('Failed to check email availability');
    }
  }

  // 電話番号重複チェック
  Future<bool> checkPhoneAvailability(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/check-phone'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['available'];
    } else {
      throw Exception('Failed to check phone number availability');
    }
  }
}
