import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
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
      return json.decode(utf8.decode(response.bodyBytes));
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

  // ユーザープロフィール更新
  Future<void> updateUserProfile(
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

  // 店舗プロフィール更新
  Future<void> updateStoreProfile(
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

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw ApiException(
          'Failed to sign up. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // 営業許可証イメージアップロード
  Future<void> uploadLicenseImage(String storeId, File imageFile) async {
    // Firebase Authからトークンを取得
    final token = await _getIdToken();
    final uri = Uri.parse('$baseUrl/api/stores/upload-license');

    final request = http.MultipartRequest('POST', uri);

    // Firebase Authから取得한トークンを使用
    request.headers['Authorization'] = 'Bearer $token';

    // storeIdを formData に追加
    request.fields['storeId'] = storeId;
    request.files.add(
      await http.MultipartFile.fromPath(
        'licenseImage',
        imageFile.path,
      ),
    );

    final response = await request.send();

    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      throw ApiException(
          'Failed to upload license image. Status: ${response.statusCode}, Body: $responseBody');
    }
    print('License image uploaded successfully!');
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
      final data = jsonDecode(response.body);
      return data['available'];
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

    if (response.statusCode == 201) {
      // 201 Created
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw ApiException(
          'Failed to add new store. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
