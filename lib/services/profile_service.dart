import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoyaku_mate_provider/models/store_license.dart';
import 'package:yoyaku_mate_provider/models/store_profile.dart';
import 'package:yoyaku_mate_provider/models/user_profile.dart';
import 'api_exception.dart';
import '../models/provider_profile.dart';

class ProviderProfileService {
  final String baseUrl;
  ProviderProfileService({required this.baseUrl});

  // 認証 Token 取得
  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException('ユーザーがログインしていません。');
    }
    final String? token = await user.getIdToken();
    if (token == null) {
      throw ApiException('認証トークンの取得に失敗しました。再ログインしてください。');
    }
    return token;
  }

  // ユーザープロフィール取得
  Future<Map<String, dynamic>> fetchUserProfile(String firebaseUid) async {
    final token = await _getIdToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/provider_user/firebase_uid?uid=$firebaseUid'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      // print('--- [ProfileService] fetchUserProfile Response ---');
      // print(responseData.keys.toList());

      // Save Login Token from Profile Fetch
      // Response is wrapped in { "status": "success", "data": { ... } }
      if (responseData.containsKey('data') && responseData['data'] is Map) {
        final data = responseData['data'];
        if (data.containsKey('login_token')) {
          final token = data['login_token'];
          if (token != null && token.toString().isNotEmpty) {
            // print(
            //     '--- [ProfileService] Saving Login Token: ${token.substring(0, 5)}... ---');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('login_token', token);
          } else {
            // print('--- [ProfileService] Login Token is empty/null! ---');
          }
        } else {
          // print(
          //     '--- [ProfileService] Response data missing login_token key! ---');
        }
      } else {
        // print('--- [ProfileService] Response missing data key! ---');
      }

      return responseData;
    } else {
      throw ApiException(
          'Failed to load user profile. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchAllStores() async {
    // 現在ログインされているユーザーのIDトークンを取得
    final token = await _getIdToken();
    final url = Uri.parse('$baseUrl/api/provider_stores/store-list');

    // print('--- Calling fetchMyStores ---');
    // print('URL: $url');
    // print('Token: Bearer ${token.substring(0, 30)}...');
    // -----------------------

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // final responseBody = utf8.decode(response.bodyBytes);
      // print('--- Response from /my-list ---');
      // print(responseBody);
      // print('----------------------------');

      // 成功時、JSONデータをデコードして返却
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      // 失敗時、エラーを投げてViewModelが処理するようにする
      // print('--- fetchMyStores FAILED ---');
      // print('Status: ${response.statusCode}');
      // print('Body: ${response.body}');
      throw ApiException(
          'Failed to load my stores. Status: ${response.statusCode}');
    }
  }

  // ユーザープロフィール更新。更新後の UserProfile を返却 (REST 標準)
  Future<UserProfile> updateUserProfile(
      String mongoUserId, Map<String, dynamic> update) async {
    final token = await _getIdToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/provider_user?user_id=$mongoUserId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(update),
    );
    if (response.statusCode != 200) {
      throw ApiException(
          'Failed to update user profile. Status: ${response.statusCode}, Body: ${response.body}');
    }
    final responseData = json.decode(utf8.decode(response.bodyBytes));
    final userData = responseData['data'] ?? responseData;
    return UserProfile.fromJson(userData as Map<String, dynamic>);
  }

  Future<UserProfile> uploadUserImage(File imageFile, String idToken) async {
    final uri = Uri.parse('$baseUrl/api/provider_user/image');
    try {
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $idToken';

      request.files.add(
        await http.MultipartFile.fromPath(
          'userImage',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        final userData = jsonResponse['data'] ?? jsonResponse;
        return UserProfile.fromJson(userData);
      } else {
        throw ApiException(
            jsonResponse['message'] ?? 'Failed to upload user image',
            statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Avatar upload failed: ${e.toString()}');
    }
  }

  Future<StoreProfile> uploadStoreImage(
      File imageFile, String storeId, String idToken) async {
    final uri = Uri.parse('$baseUrl/api/provider_store/$storeId/image');
    try {
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $idToken';

      request.files.add(
        await http.MultipartFile.fromPath(
          'storeImage',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        final storeData = jsonResponse['data'] ?? jsonResponse;
        return StoreProfile.fromJson(storeData);
      } else {
        throw ApiException(
            jsonResponse['message'] ?? 'Failed to upload store image',
            statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Store logo upload failed: ${e.toString()}');
    }
  }

  // 店舗プロフィール取得
  Future<Map<String, dynamic>> fetchStoreProfile(String storeId) async {
    final token = await _getIdToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/provider_store?store_id=$storeId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw ApiException(
          'Failed to load store profile. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // 店舗ライセンス情報取得
  Future<Map<String, dynamic>> fetchStoreLicense(String storeId) async {
    final token = await _getIdToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/provider_store/license?store_id=$storeId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw ApiException(
          'Failed to load store license. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // 店舗プロフィール更新。更新後の StoreProfile を返却 (REST 標準)
  Future<StoreProfile> updateStoreProfile(
      String storeId, Map<String, dynamic> update) async {
    final token = await _getIdToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/provider_store?store_id=$storeId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(update),
    );
    if (response.statusCode != 200) {
      throw ApiException(
          'Failed to update store profile. Status: ${response.statusCode}, Body: ${response.body}');
    }
    final responseData = json.decode(utf8.decode(response.bodyBytes));
    final storeData = responseData['data'] ?? responseData;
    return StoreProfile.fromJson(storeData as Map<String, dynamic>);
  }

  // 会員加入
  Future<Map<String, dynamic>> signUp(
      ProviderProfile profile, String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/signup'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(profile.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      // Save Login Token
      if (responseData.containsKey('user') &&
          responseData['user']['login_token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'login_token', responseData['user']['login_token']);
      } else if (responseData.containsKey('login_token')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('login_token', responseData['login_token']);
      }
      return responseData;
    } else {
      throw ApiException(
          'Failed to sign up. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // 営業許可証イメージアップロード。更新後の StoreLicense を返却 (REST 標準)
  Future<StoreLicense> uploadLicenseImage(
      String storeId, File imageFile) async {
    final token = await _getIdToken();
    final uri = Uri.parse('$baseUrl/api/stores/upload-license');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['storeId'] = storeId;
    request.files.add(
      await http.MultipartFile.fromPath('licenseImage', imageFile.path),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw ApiException(
          'Failed to upload license image. Status: ${response.statusCode}, Body: $responseBody');
    }

    final responseData = json.decode(responseBody);
    final licenseData = responseData['data'] ?? responseData;
    return StoreLicense.fromJson(licenseData as Map<String, dynamic>);
  }

  // 店舗存在確認
  Future<bool> checkStoreExists(String storeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/check-store?store_id=$storeId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['exists'] as bool;
    } else {
      throw ApiException('Failed to check store existence: ${response.body}');
    }
  }

  // E-mail 中腹確認
  Future<bool> checkEmailAvailability(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/check-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final data = jsonResponse['data'];
      if (data == null || data['available'] == null) {
        throw ApiException('Invalid response from server');
      }
      return data['available'] as bool;
    } else {
      throw ApiException('Failed to check email availability');
    }
  }

  // 電話番号中腹確認
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
      throw ApiException('Failed to check phone number availability');
    }
  }

  Future<Map<String, dynamic>> addNewStore(
      ProviderProfile profile, String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/stores/add'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(profile.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // 201 Created
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw ApiException(
          'Failed to add new store. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> joinStore(String storeId) async {
    final token = await _getIdToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/stores/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'store_id': storeId}),
    );

    if (response.statusCode != 201) {
      throw ApiException(
          'Failed to join store. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // 店舗スタッフリスト取得
  Future<List<dynamic>> fetchStoreStaff(String storeId) async {
    final token = await _getIdToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/stores/$storeId/staff'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded['data'] == null) {
        return [];
      }
      return decoded['data'] as List<dynamic>;
    } else {
      throw ApiException(
          'Failed to fetch store staff. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // スタッフ状態更新
  Future<void> updateStoreStaffStatus(
      String storeId, String staffId, String status) async {
    final token = await _getIdToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/api/stores/$storeId/staff/$staffId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw ApiException(
          'Failed to update staff status. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // スタッフ権限更新
  Future<void> updateStoreStaffPermissions(
      String storeId, String staffId, List<String> permissions) async {
    final token = await _getIdToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/api/stores/$storeId/staff/$staffId/permissions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'permissions': permissions}),
    );

    if (response.statusCode != 200) {
      throw ApiException(
          'Failed to update staff permissions. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
