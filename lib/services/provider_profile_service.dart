import 'dart:convert';
import 'package:http/http.dart' as http;

class ProviderProfileService {
  final String baseUrl;
  ProviderProfileService({required this.baseUrl});

  // 사용자 프로필 조회
  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/provider_user?user_id=$userId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  // 사용자 프로필 수정
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

  // 매장 프로필 조회
  Future<Map<String, dynamic>> fetchStoreProfile(String storeId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/provider_store?store_id=$storeId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load store profile');
    }
  }

  // 매장 프로필 수정
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
}
