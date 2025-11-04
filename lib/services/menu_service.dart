import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

  Future<String> _uploadImage(Uint8List imageBytes, String filename) async {
    final uri = Uri.parse('$_baseUrl/api/upload-image');
    try {
      var request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes('image', imageBytes,
          filename: filename));
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody)['url'];
      } else {
        throw ApiException(
            json.decode(responseBody)['message'] ?? 'Failed to upload image',
            statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Image upload failed: ${e.toString()}');
    }
  }

  Future<MenuListItem> uploadMenuImage(String menuId, File imageFile) async {
    final uri = Uri.parse('$_baseUrl/api/menus/$menuId/image');
    try {
      // multipart/form-data要請生成
      var request = http.MultipartRequest('POST', uri);

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

  Future<void> saveMenuItems(
      Map<String, List<MenuListItem>> categorizedMenu, String storeId) async {
    List<Map<String, dynamic>> itemsToSave = [];

    for (var entry in categorizedMenu.entries) {
      for (var item in entry.value) {
        String finalImageUrl = item.menuImageUrl;
        if (item.tempImageBytes != null) {
          try {
            final filename = '${item.menuId}.jpg';
            finalImageUrl = await _uploadImage(item.tempImageBytes!, filename);
          } catch (e) {
            print('Image upload failed for ${item.title}: $e');
          }
        }
        final itemToSave = item.copyWith(
          menuImageUrl: finalImageUrl,
          storeId: item.storeId.isNotEmpty ? item.storeId : storeId,
          updatedAt: DateTime.now(),
          clearTempImage: true,
        );
        itemsToSave.add(itemToSave.toJson());
      }
    }

    final uri =
        Uri.parse('$_baseUrl/api/menu-list/bulk-save?store_id=$storeId');
    try {
      final response = await _client.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(itemsToSave));
      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonResponse = json.decode(decodedBody);

      if (response.statusCode != 200) {
        throw ApiException(jsonResponse['message'] ?? 'Failed to save menus',
            statusCode: response.statusCode);
      }
      if (jsonResponse['status'] != 'success') {
        throw ApiException(jsonResponse['message'] ?? 'Failed to save menus');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to save menus: ${e.toString()}');
    }
  }
}
