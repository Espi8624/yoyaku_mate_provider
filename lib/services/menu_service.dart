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

  Future<Map<String, List<MenuListItem>>> fetchMenuItems(
      {String storeId = 'store-001'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/menu-list?store_id=$storeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['data'] != null) {
          final Map<String, dynamic> data = jsonResponse['data'];
          Map<String, List<MenuListItem>> categorizedMenus = {};

          data.forEach((category, items) {
            if (items is List) {
              List<MenuListItem> menuItems = [];
              for (var item in items) {
                try {
                  final menuItem = MenuListItem.fromJson(item);
                  menuItems.add(menuItem);
                } catch (e) {
                  // 개별 아이템 오류는 무시하고 진행
                }
              }
              categorizedMenus[category] = menuItems;
            }
          });

          return categorizedMenus;
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

  Future<List<Map<String, dynamic>>> saveMenuItems(
      Map<String, List<MenuListItem>> categorizedMenu, String storeId) async {
    try {
      final clearResponse = await http.post(
        Uri.parse('$_baseUrl/api/menu?action=clear&store_id=$storeId'),
        headers: {'Content-Type': 'application/json'},
        body: '{}',
      );

      if (clearResponse.statusCode != 200) {
        throw Exception(
            'Failed to clear menu list: ${clearResponse.statusCode}');
      }

      List<Map<String, dynamic>> itemsToSave = [];
      for (var category in categorizedMenu.keys) {
        final menuItems = categorizedMenu[category]!;
        for (var item in menuItems) {
          // menuStatus가 "disable"인 항목도 포함
          String imageUrl = item.imageUrl;
          if (item.tempImageBytes != null) {
            imageUrl = await uploadImage(item.tempImageBytes!);
          }
          final updatedItem = MenuListItem(
            id: item.id,
            storeId: item.storeId,
            menuId: item.menuId,
            category: category,
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

      print('저장될 데이터: ${json.encode(itemsToSave)}');

      final saveResponse = await http.post(
        Uri.parse('$_baseUrl/api/menu/bulk-save?store_id=$storeId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'data': itemsToSave}),
      );

      if (saveResponse.statusCode != 200) {
        throw Exception(
            'Failed to save menu items: ${saveResponse.statusCode}');
      }

      return itemsToSave;
    } catch (e) {
      rethrow;
    }
  }
}
