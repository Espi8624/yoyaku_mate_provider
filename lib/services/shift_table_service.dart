import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yoyaku_mate_provider/services/api_client.dart';
import 'package:yoyaku_mate_provider/models/shift_change_request.dart';
import 'package:yoyaku_mate_provider/models/shift_table.dart';
import 'api_exception.dart';

class ShiftTableService {
  final String baseUrl;
  ShiftTableService({required this.baseUrl});

  // 認証 Token 取得
  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ApiException('ユーザーがログインしていません。');
    }
    final String? token = await user.getIdToken();
    if (token == null) {
      throw const ApiException('認証トークンの取得に失敗しました。再ログインしてください。');
    }
    return token;
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // 指定週のシフト表を取得。まだ作成されていない週の場合は null を返す
  Future<ShiftTable?> fetchShiftTable(
      String storeId, String weekStartDate) async {
    final token = await _getIdToken();
    final response = await apiClient.get(
      Uri.parse('$baseUrl/api/stores/$storeId/shift-tables/$weekStartDate'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      return ShiftTable.fromJson(decoded['data'] as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw ApiException(
          'シフト表の取得に失敗しました。Status: ${response.statusCode}, Body: ${response.body}',
          statusCode: response.statusCode);
    }
  }

  // 指定週の空のシフト表を作成 (マネージャー専用)
  Future<void> createShiftTable(String storeId, String weekStartDate) async {
    final token = await _getIdToken();
    final response = await apiClient.post(
      Uri.parse('$baseUrl/api/stores/$storeId/shift-tables'),
      headers: _headers(token),
      body: jsonEncode({'week_start_date': weekStartDate}),
    );

    if (response.statusCode != 201) {
      throw ApiException(
          'シフト表の作成に失敗しました。Status: ${response.statusCode}, Body: ${response.body}',
          statusCode: response.statusCode);
    }
  }

  // シフトを1件追加 (マネージャー専用)
  Future<void> addShift(
    String storeId,
    String weekStartDate, {
    required String staffId,
    required String day,
    required String startTime,
    required String endTime,
  }) async {
    final token = await _getIdToken();
    final response = await apiClient.post(
      Uri.parse(
          '$baseUrl/api/stores/$storeId/shift-tables/$weekStartDate/shifts'),
      headers: _headers(token),
      body: jsonEncode({
        'staff_id': staffId,
        'day': day,
        'start_time': startTime,
        'end_time': endTime,
      }),
    );

    if (response.statusCode != 201) {
      throw ApiException(
          'シフトの追加に失敗しました。Status: ${response.statusCode}, Body: ${response.body}',
          statusCode: response.statusCode);
    }
  }

  // シフトを1件更新 (マネージャー専用)
  Future<void> updateShift(
    String storeId,
    String weekStartDate,
    String shiftId, {
    required String staffId,
    required String day,
    required String startTime,
    required String endTime,
  }) async {
    final token = await _getIdToken();
    final response = await apiClient.patch(
      Uri.parse(
          '$baseUrl/api/stores/$storeId/shift-tables/$weekStartDate/shifts/$shiftId'),
      headers: _headers(token),
      body: jsonEncode({
        'staff_id': staffId,
        'day': day,
        'start_time': startTime,
        'end_time': endTime,
      }),
    );

    if (response.statusCode != 200) {
      throw ApiException(
          'シフトの更新に失敗しました。Status: ${response.statusCode}, Body: ${response.body}',
          statusCode: response.statusCode);
    }
  }

  // シフトを1件削除 (マネージャー専用)
  Future<void> deleteShift(
      String storeId, String weekStartDate, String shiftId) async {
    final token = await _getIdToken();
    final response = await apiClient.delete(
      Uri.parse(
          '$baseUrl/api/stores/$storeId/shift-tables/$weekStartDate/shifts/$shiftId'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw ApiException(
          'シフトの削除に失敗しました。Status: ${response.statusCode}, Body: ${response.body}',
          statusCode: response.statusCode);
    }
  }

  // 必要人員設定・勤務可能時間をもとにシフトを自動配置 (マネージャー専用)
  // mode: 'fill_gaps' (既存シフトは維持し不足分のみ追加) / 'replace_all' (全て新規に生成)
  Future<void> autoGenerateShifts(
    String storeId,
    String weekStartDate, {
    required String mode,
  }) async {
    final token = await _getIdToken();
    final response = await apiClient.post(
      Uri.parse(
          '$baseUrl/api/stores/$storeId/shift-tables/$weekStartDate/auto-generate'),
      headers: _headers(token),
      body: jsonEncode({'mode': mode}),
    );

    if (response.statusCode != 200) {
      throw ApiException(
          'シフトの自動配置に失敗しました。Status: ${response.statusCode}, Body: ${response.body}',
          statusCode: response.statusCode);
    }
  }

  // 週間シフト表に対する修正依頼一覧を取得 (承認済みスタッフ/マネージャー共通)
  Future<List<ShiftChangeRequest>> fetchChangeRequests(
      String storeId, String weekStartDate) async {
    final token = await _getIdToken();
    final response = await apiClient.get(
      Uri.parse(
          '$baseUrl/api/stores/$storeId/shift-tables/$weekStartDate/change-requests'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw ApiException(
          '修正依頼の取得に失敗しました。Status: ${response.statusCode}, Body: ${response.body}',
          statusCode: response.statusCode);
    }
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    return (decoded['data'] as List<dynamic>? ?? [])
        .map((e) => ShiftChangeRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // シフトブロックに対する修正依頼を1件送信 (承認済みスタッフ用)。
  // From/To とも、シフトの追加/更新(addShift/updateShift)と同じ day/start_time/end_time
  // 形式で渡す
  Future<void> createChangeRequest(
    String storeId,
    String weekStartDate, {
    required String targetShiftId,
    required String fromDay,
    required String fromStartTime,
    required String fromEndTime,
    required String toDay,
    required String toStartTime,
    required String toEndTime,
  }) async {
    final token = await _getIdToken();
    final response = await apiClient.post(
      Uri.parse(
          '$baseUrl/api/stores/$storeId/shift-tables/$weekStartDate/change-requests'),
      headers: _headers(token),
      body: jsonEncode({
        'target_shift_id': targetShiftId,
        'from_day': fromDay,
        'from_start_time': fromStartTime,
        'from_end_time': fromEndTime,
        'to_day': toDay,
        'to_start_time': toStartTime,
        'to_end_time': toEndTime,
      }),
    );

    if (response.statusCode != 201) {
      throw ApiException(
          '修正依頼の送信に失敗しました。Status: ${response.statusCode}, Body: ${response.body}',
          statusCode: response.statusCode);
    }
  }

  // その週の未処理の修正依頼を全て処理済みにする (マネージャー専用)
  Future<void> resolveChangeRequests(
      String storeId, String weekStartDate) async {
    final token = await _getIdToken();
    final response = await apiClient.post(
      Uri.parse(
          '$baseUrl/api/stores/$storeId/shift-tables/$weekStartDate/change-requests/resolve'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw ApiException(
          '修正依頼の処理に失敗しました。Status: ${response.statusCode}, Body: ${response.body}',
          statusCode: response.statusCode);
    }
  }

  // その週の未処理の修正依頼を、古い順に実際のシフト表へ反映する (マネージャー専用)。
  // 衝突に当たった場合は途中で止まり、その1件を結果に含めて返す。呼び出し側はマネージャーの
  // 判断を resolutions に足して、衝突が無くなる(done=true)まで呼び直すウィザード方式
  Future<ChangeRequestApplyResult> applyChangeRequests(
    String storeId,
    String weekStartDate,
    List<ChangeRequestResolution> resolutions,
  ) async {
    final token = await _getIdToken();
    final response = await apiClient.post(
      Uri.parse(
          '$baseUrl/api/stores/$storeId/shift-tables/$weekStartDate/change-requests/apply'),
      headers: _headers(token),
      body: jsonEncode({
        'resolutions': resolutions.map((r) => r.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw ApiException(
          '修正依頼の適用に失敗しました。Status: ${response.statusCode}, Body: ${response.body}',
          statusCode: response.statusCode);
    }
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    return ChangeRequestApplyResult.fromJson(
        decoded['data'] as Map<String, dynamic>);
  }

  // 修正依頼を1件削除する (マネージャー専用。衝突で見送られ、対応不要になった依頼を
  // 手動で消す用)
  Future<void> deleteChangeRequest(
      String storeId, String weekStartDate, String requestId) async {
    final token = await _getIdToken();
    final response = await apiClient.delete(
      Uri.parse(
          '$baseUrl/api/stores/$storeId/shift-tables/$weekStartDate/change-requests/$requestId'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw ApiException(
          '修正依頼の削除に失敗しました。Status: ${response.statusCode}, Body: ${response.body}',
          statusCode: response.statusCode);
    }
  }
}
