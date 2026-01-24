import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class StatisticsService {
  final String baseUrl;

  StatisticsService({required this.baseUrl});

  Future<Map<String, dynamic>> fetchStatistics(String storeId,
      {String period = 'auto'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final idToken = await user.getIdToken();
    final url =
        Uri.parse('$baseUrl/api/statistics?store_id=$storeId&period=$period');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded['status'] == 'success') {
        return decoded['data'];
      } else {
        throw Exception(decoded['message'] ?? 'Failed to load statistics');
      }
    } else {
      throw Exception('Failed to load statistics: ${response.statusCode}');
    }
  }
}
