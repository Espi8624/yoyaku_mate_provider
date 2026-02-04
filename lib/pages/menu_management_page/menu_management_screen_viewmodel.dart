import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/menu_list.dart';
import '../../services/api_exception.dart';
import '../../services/menu_service.dart';

// 保存ステータス列挙型
enum SaveStatus { saved, saving, error }

class MenuManagementScreenViewModel extends ChangeNotifier {
  final MenuService _menuService;
  final String storeId;

  MenuManagementScreenViewModel({
    required this.storeId,
    required MenuService menuService,
  }) : _menuService = menuService {
    loadMenuData();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SaveStatus _saveStatus = SaveStatus.saved;
  SaveStatus get saveStatus => _saveStatus;

  List<MenuListItem> _menuItems = [];
  Map<String, List<MenuListItem>> _categorizedMenu = {};
  Map<String, List<MenuListItem>> get categorizedMenu => _categorizedMenu;

  List<String> _categories = [];
  List<String> get categories => _categories;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  Timer? _autoSaveTimer;

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSaveStatus(SaveStatus status) {
    _saveStatus = status;
    notifyListeners();
  }

  Future<void> loadMenuData() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _menuItems = await _menuService.fetchMenuItems(storeId);
      _updateCategorizedMenu();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  void _updateCategorizedMenu() {
    final newCategorizedMenu = <String, List<MenuListItem>>{};
    for (var item in _menuItems) {
      final category = item.category.isNotEmpty ? item.category : '未分類';
      (newCategorizedMenu[category] ??= []).add(item);
    }
    _categorizedMenu = newCategorizedMenu;
    _categories = newCategorizedMenu.keys.toList();
    notifyListeners();
  }

  void addCategory(String categoryName) {
    if (!_categories.contains(categoryName)) {
      _categories.add(categoryName);
      _categorizedMenu[categoryName] = [];
      notifyListeners();
    }
  }

  Future<void> editCategory(String oldName, String newName) async {
    if (!_categories.contains(oldName) || _categories.contains(newName)) {
      return;
    }

    _setSaveStatus(SaveStatus.saving);
    try {
      final menuList = _categorizedMenu[oldName] ?? [];

      // 모든 메뉴의 카테고리를 업데이트
      for (var item in menuList) {
        final updatedItem = item.copyWith(category: newName);
        await _menuService.updateSingleMenu(updatedItem);
      }

      // ローカルステータス更新
      final index = _categories.indexOf(oldName);
      _categories[index] = newName;
      _categorizedMenu[newName] =
          menuList.map((item) => item.copyWith(category: newName)).toList();
      _categorizedMenu.remove(oldName);

      _menuItems = _menuItems
          .map((item) => item.category == oldName
              ? item.copyWith(category: newName)
              : item)
          .toList();

      _setSaveStatus(SaveStatus.saved);
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setSaveStatus(SaveStatus.error);
      rethrow;
    }
  }

  // カテゴリ削除 - 即時サーバーに反映
  Future<void> deleteCategory(int index) async {
    final category = _categories[index];
    final menuList = _categorizedMenu[category] ?? [];

    _setSaveStatus(SaveStatus.saving);
    try {
      // 全てのメニューをdisableに変更
      for (var item in menuList) {
        await _menuService.deleteSingleMenu(item.id);
      }

      // ローカルステータス更新
      _menuItems.removeWhere((item) => item.category == category);
      _categories.removeAt(index);
      _categorizedMenu.remove(category);

      _setSaveStatus(SaveStatus.saved);
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setSaveStatus(SaveStatus.error);
      rethrow;
    }
  }

  // 新規メニュー追加
  Future<MenuListItem?> addMenu(MenuListItem newMenu) async {
    _setSaveStatus(SaveStatus.saving);
    try {
      final savedMenu = await _menuService.createSingleMenu(newMenu, storeId);

      _menuItems.add(savedMenu);
      _updateCategorizedMenu();

      _setSaveStatus(SaveStatus.saved);
      return savedMenu;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setSaveStatus(SaveStatus.error);
      notifyListeners();
      return null;
    }
  }

  // イメージ付きメニュー更新
  Future<void> updateMenuWithImage(
      MenuListItem menuData, File imageFile) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final uploadedMenu =
          await _menuService.uploadMenuImage(menuData.id, imageFile);

      final finalUpdatedMenu = uploadedMenu.copyWith(
        title: menuData.title,
        description: menuData.description,
        price: menuData.price,
        category: menuData.category,
        titleTranslations: menuData.titleTranslations,
        descriptionTranslations: menuData.descriptionTranslations,
      );

      // ローカルステータス更新
      final index =
          _menuItems.indexWhere((item) => item.id == finalUpdatedMenu.id);
      if (index != -1) {
        _menuItems[index] = finalUpdatedMenu;
        _updateCategorizedMenu();
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // メニュー編集（テキスト情報のみ）
  Future<void> editMenu(MenuListItem updatedMenu) async {
    final index = _menuItems.indexWhere((item) =>
        (item.id.isNotEmpty && item.id == updatedMenu.id) ||
        (item.id.isEmpty && item.menuId == updatedMenu.menuId));

    if (index != -1) {
      _menuItems[index] = updatedMenu;
      _updateCategorizedMenu();
    }

    _autoSave(updatedMenu);
  }

  void _autoSave(MenuListItem menu) {
    _autoSaveTimer?.cancel();
    _setSaveStatus(SaveStatus.saving);

    _autoSaveTimer = Timer(Duration(seconds: 1), () async {
      try {
        await _menuService.updateSingleMenu(menu);
        _setSaveStatus(SaveStatus.saved);
      } on ApiException catch (e) {
        _errorMessage = e.message;
        _setSaveStatus(SaveStatus.error);
        notifyListeners();
      }
    });
  }

  // メニュー削除（状態変更）
  Future<void> deleteMenu(String category, int menuIndex) async {
    final menuItem = _categorizedMenu[category]![menuIndex];

    _setSaveStatus(SaveStatus.saving);
    try {
      await _menuService.deleteSingleMenu(menuItem.id);

      // ローカルステータス更新
      final index = _menuItems.indexWhere((item) => item.id == menuItem.id);
      if (index != -1) {
        _menuItems[index] = menuItem.copyWith(
          menuStatus: 'disable',
          updatedAt: DateTime.now(),
        );
        _updateCategorizedMenu();
      }

      _setSaveStatus(SaveStatus.saved);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setSaveStatus(SaveStatus.error);
      rethrow;
    }
  }

  // 全体メニュー削除（状態変更）
  Future<void> deleteAllMenus() async {
    _setSaveStatus(SaveStatus.saving);
    try {
      for (var item in _menuItems) {
        if (item.menuStatus != 'disable') {
          await _menuService.deleteSingleMenu(item.id);
        }
      }

      _menuItems = _menuItems
          .map((item) =>
              item.copyWith(menuStatus: 'disable', updatedAt: DateTime.now()))
          .toList();
      _updateCategorizedMenu();

      _setSaveStatus(SaveStatus.saved);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setSaveStatus(SaveStatus.error);
      rethrow;
    }
  }
}
