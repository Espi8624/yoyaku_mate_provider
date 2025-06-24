import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/store_settings.dart';

class StoreSettingsService {
  final String baseUrl;
  StoreSettingsService({required this.baseUrl});

  Future<StoreSettings> fetchStoreSettings(String storeId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/store_settings?store_id=$storeId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // 서버 응답이 {status: success, data: {...}} 형태일 경우
      return StoreSettings.fromJson(data['data']);
    } else {
      throw Exception('Failed to load store settings');
    }
  }

  Future<void> updateStoreSettings(StoreSettings settings) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/store_settings?store_id=${settings.storeId}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(settings.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update store settings');
    }
  }
}
