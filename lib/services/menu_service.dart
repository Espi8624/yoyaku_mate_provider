import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/menu_list.dart';

class MenuService {
  static final MenuService _instance = MenuService._internal();
  static const String _baseUrl = 'http://localhost:8080';

  factory MenuService() {
    return _instance;
  }

  MenuService._internal();

  Future<List<MenuListItem>> fetchMenuItems(
      {String storeId = 'store-001'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/menu-list?store_id=$storeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] != 'success') {
          throw Exception(
              'Failed to fetch menu items: ${jsonResponse['message']}');
        }

        if (jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          List<MenuListItem> menuItems = [];

          for (var item in data) {
            try {
              final menuItem = MenuListItem.fromJson(item);
              menuItems.add(menuItem);
            } catch (e) {
              print('Error parsing menu item: $e');
            }
          }

          return menuItems;
        }
      }

      throw Exception('Failed to fetch menu items: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadImage(Uint8List imageBytes) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/upload-image'),
      headers: {'Content-Type': 'multipart/form-data'},
      body: imageBytes,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['url'];
    }
    throw Exception('Failed to upload image');
  }

  Future<List<MenuListItem>> saveMenuItems(
      Map<String, List<MenuListItem>> categorizedMenu, String storeId) async {
    try {
      List<Map<String, dynamic>> itemsToSave = [];
      for (var entry in categorizedMenu.entries) {
        final category = entry.key;
        final items = entry.value;
        for (var item in items) {
          String imageUrl = item.imageUrl;
          if (item.tempImageBytes != null) {
            try {
              print('이미지 업로드 시도: ${item.title} (카테고리: $category)');
              imageUrl = await uploadImage(item.tempImageBytes!);
              print('이미지 업로드 성공: $imageUrl');
            } catch (e) {
              print('이미지 업로드 실패 - ${item.title}: $e');
              imageUrl = item.imageUrl; // 기존 URL 유지
            }
          }
          final updatedItem = MenuListItem(
            id: item.id,
            storeId: item.storeId.isNotEmpty ? item.storeId : storeId,
            menuId: item.menuId.isNotEmpty
                ? item.menuId
                : DateTime.now().millisecondsSinceEpoch.toString(),
            category: item.category,
            title: item.title,
            description: item.description,
            price: item.price,
            imageUrl: imageUrl,
            createdAt: item.createdAt,
            updatedAt: DateTime.now(),
            menuStatus: item.menuStatus,
            tempImageBytes: null,
          );
          itemsToSave.add(updatedItem.toJson());
        }
      }

      final saveResponse = await http.post(
        Uri.parse('$_baseUrl/api/menu-list/bulk-save?store_id=$storeId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(itemsToSave),
      );

      if (saveResponse.statusCode != 200) {
        throw Exception('メニューの保存に失敗しました: ${saveResponse.statusCode}');
      }

      final Map<String, dynamic> jsonResponse = json.decode(saveResponse.body);
      if (jsonResponse['status'] != 'success') {
        throw Exception('メニューの保存に失敗しました: ${jsonResponse['message']}');
      }

      final List<dynamic> savedData = jsonResponse['data'];
      final List<MenuListItem> updatedMenuItems = savedData
          .cast<Map<String, dynamic>>()
          .map((item) => MenuListItem.fromJson({
                ...item,
                'storeId': item['storeId']?.toString() ?? storeId,
                'menuId': item['menuId']?.toString() ??
                    (item['id']?.toString() ??
                        DateTime.now().millisecondsSinceEpoch.toString()),
              }))
          .toList();

      return updatedMenuItems;
    } catch (e) {
      print('saveMenuItems 에러 발생: $e');
      throw Exception('メニューの保存に失敗しました: $e');
    }
  }
}