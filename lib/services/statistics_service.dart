import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class StatisticsService {
  final String baseUrl;

  StatisticsService({required this.baseUrl});

  Future<Map<String, dynamic>> fetchStatistics(String storeId,
      {String period = 'auto', DateTime? date}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final idToken = await user.getIdToken();
    var queryParams = 'store_id=$storeId&period=$period';
    if (date != null) {
      // Format DateTime as YYYY-MM-DD
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      queryParams += '&date=$dateStr';
    }

    final url = Uri.parse('$baseUrl/api/statistics?$queryParams');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      // Use compute to parse JSON in a background isolate
      return await compute(_parseStatistics, response.body);
    } else {
      throw Exception('Failed to load statistics: ${response.statusCode}');
    }
  }
}

// Top-level function for isolate
Map<String, dynamic> _parseStatistics(String responseBody) {
  final decoded = jsonDecode(responseBody);
  if (decoded['status'] == 'success') {
    return decoded['data'] as Map<String, dynamic>;
  } else {
    throw Exception(decoded['message'] ?? 'Failed to load statistics');
  }
}
