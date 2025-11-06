import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/menu_list.dart';
import 'api_exception.dart';

class MenuService {
  final http.Client _client;
  final String _baseUrl;

  MenuService({
    http.Client? client,
    String baseUrl = 'https://saboten-server.fly.dev',
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  Future<List<MenuListItem>> fetchMenuItems(String storeId) async {
    final uri = Uri.parse('$_baseUrl/api/menu-list?store_id=$storeId');
    try {
      final response =
          await _client.get(uri, headers: {'Content-Type': 'application/json'});
      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonResponse = json.decode(decodedBody);

      if (response.statusCode == 200) {
        if (jsonResponse['status'] != 'success') {
          throw ApiException(
              jsonResponse['message'] ?? 'Failed to fetch menu items');
        }
        final List<dynamic> data = jsonResponse['data'] ?? [];
        return data.map((item) => MenuListItem.fromJson(item)).toList();
      } else {
        throw ApiException(
            jsonResponse['message'] ?? 'Failed to fetch menu items',
            statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Network error or server is unavailable: ${e.toString()}');
    }
  }

  // Future<String> _uploadImage(Uint8List imageBytes, String filename) async {
  //   final uri = Uri.parse('$_baseUrl/api/upload-image');
  //   try {
  //     var request = http.MultipartRequest('POST', uri);
  //     request.files.add(http.MultipartFile.fromBytes('image', imageBytes,
  //         filename: filename));
  //     final response = await request.send();
  //     final responseBody = await response.stream.bytesToString();

  //     if (response.statusCode == 200) {
  //       return json.decode(responseBody)['url'];
  //     } else {
  //       throw ApiException(
  //           json.decode(responseBody)['message'] ?? 'Failed to upload image',
  //           statusCode: response.statusCode);
  //     }
  //   } catch (e) {
  //     if (e is ApiException) rethrow;
  //     throw ApiException('Image upload failed: ${e.toString()}');
  //   }
  // }

  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw ApiException('User not logged in.');
    final token = await user.getIdToken();
    if (token == null) throw ApiException('Failed to get auth token.');
    return token;
  }

  Future<MenuListItem> uploadMenuImage(String menuId, File imageFile) async {
    final uri = Uri.parse('$_baseUrl/api/menus/$menuId/image');
    try {
      // multipart/form-data要請生成
      var request = http.MultipartRequest('POST', uri);

      final token = await _getIdToken();
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'menuImage',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);

      if (response.statusCode == 200) {
        final menuData = jsonResponse['data'] ?? jsonResponse;
        return MenuListItem.fromJson(menuData);
      } else {
        throw ApiException(
            jsonResponse['message'] ?? 'Failed to upload menu image',
            statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Menu image upload failed: ${e.toString()}');
    }
  }

  Future<List<MenuListItem>> saveMenuItems(
      Map<String, List<MenuListItem>> categorizedMenu, String storeId) async {
    final List<Map<String, dynamic>> itemsToSave = [];
    categorizedMenu.forEach((_, menuList) {
      for (var item in menuList) {
        itemsToSave.add(item.toJson());
      }
    });

    final uri =
        Uri.parse('$_baseUrl/api/menu-list/bulk-save?store_id=$storeId');
    try {
      final token = await _getIdToken();
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(itemsToSave),
      );

      if (response.statusCode != 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);
        throw ApiException(jsonResponse['message'] ?? 'Failed to save menus',
            statusCode: response.statusCode);
      }

      // 応答パーシング
      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonResponse = json.decode(decodedBody);

      if (jsonResponse['status'] == 'success') {
        final List<dynamic> data = jsonResponse['data'] ?? [];
        return data.map((item) => MenuListItem.fromJson(item)).toList();
      }

      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to save menus: ${e.toString()}');
    }
  }

  // 単一メニュー更新
  Future<MenuListItem> updateSingleMenu(MenuListItem menu) async {
    final uri = Uri.parse('$_baseUrl/api/menu-list');
    try {
      final token = await _getIdToken();
      final response = await _client.patch(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(menu.toJson()),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonResponse = json.decode(decodedBody);

      if (response.statusCode == 200) {
        if (jsonResponse['status'] != 'success') {
          throw ApiException(
              jsonResponse['message'] ?? 'Failed to update menu');
        }
        final menuData = jsonResponse['data'] ?? jsonResponse;
        return MenuListItem.fromJson(menuData);
      } else {
        throw ApiException(jsonResponse['message'] ?? 'Failed to update menu',
            statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Menu update failed: ${e.toString()}');
    }
  }

  // 新規メニュー保存
  Future<MenuListItem> createSingleMenu(
      MenuListItem menu, String storeId) async {
    final uri =
        Uri.parse('$_baseUrl/api/menu-list/bulk-save?store_id=$storeId');
    try {
      final token = await _getIdToken();
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode([menu.toJson()]),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonResponse = json.decode(decodedBody);

      if (response.statusCode == 200) {
        if (jsonResponse['status'] != 'success') {
          throw ApiException(
              jsonResponse['message'] ?? 'Failed to create menu');
        }
        final List<dynamic> data = jsonResponse['data'] ?? [];
        if (data.isEmpty) {
          throw ApiException('No menu returned from server');
        }
        return MenuListItem.fromJson(data.first);
      } else {
        throw ApiException(jsonResponse['message'] ?? 'Failed to create menu',
            statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Menu creation failed: ${e.toString()}');
    }
  }

  // メニュー削除（状態変更）
  Future<MenuListItem> deleteSingleMenu(String menuId) async {
    final uri = Uri.parse('$_baseUrl/api/menu-list');
    try {
      final token = await _getIdToken();
      final response = await _client.patch(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id': menuId,
          'menu_status': 'disable',
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonResponse = json.decode(decodedBody);

      if (response.statusCode == 200) {
        if (jsonResponse['status'] != 'success') {
          throw ApiException(
              jsonResponse['message'] ?? 'Failed to delete menu');
        }
        final menuData = jsonResponse['data'] ?? jsonResponse;
        return MenuListItem.fromJson(menuData);
      } else {
        throw ApiException(jsonResponse['message'] ?? 'Failed to delete menu',
            statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Menu deletion failed: ${e.toString()}');
    }
  }
}
