import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:yoyaku_mate_provider/services/api_client.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatisticsService {
  final String baseUrl;

  StatisticsService({required this.baseUrl});

  /// period: 'auto'(今日を時間帯別) または 'weekly'(今週=日〜土を曜日別、常に直近の週固定)。
  /// 過去の期間を遡って取得することはできない。
  Future<Map<String, dynamic>> fetchStatistics(String storeId,
      {String period = 'auto'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final idToken = await user.getIdToken();
    final queryParams = 'store_id=$storeId&period=$period';

    final url = Uri.parse('$baseUrl/api/statistics?$queryParams');

    final response = await apiClient.get(
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
