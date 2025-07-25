import 'package:flutter/material.dart';
import '../../models/menu_list.dart';
import '../../services/api_exception.dart';
import '../../services/menu_service.dart';

class MenuManagementViewModel extends ChangeNotifier {
  final MenuService _menuService;
  final String storeId;

  MenuManagementViewModel(
      {required this.storeId, required MenuService menuService})
      : _menuService = menuService {
    loadMenuData();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<MenuListItem> _menuItems = [];
  Map<String, List<MenuListItem>> _categorizedMenu = {};
  Map<String, List<MenuListItem>> get categorizedMenu => _categorizedMenu;

  List<String> _categories = [];
  List<String> get categories => _categories;

  late Map<String, List<MenuListItem>> _originalMenuData;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadMenuData() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _menuItems = await _menuService.fetchMenuItems(storeId);
      _updateAndBackupCategorizedMenu();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  void _updateAndBackupCategorizedMenu() {
    final newCategorizedMenu = <String, List<MenuListItem>>{};
    for (var item in _menuItems) {
      final category = item.category.isNotEmpty ? item.category : '未分類';
      (newCategorizedMenu[category] ??= []).add(item);
    }
    _categorizedMenu = newCategorizedMenu;
    _originalMenuData = {
      for (var entry in _categorizedMenu.entries)
        entry.key: List.from(entry.value)
    };
    _categories = newCategorizedMenu.keys.toList();
    notifyListeners();
  }

  bool hasChanges() {
    if (_categorizedMenu.keys.toSet() != _originalMenuData.keys.toSet())
      return true;
    for (final category in _categorizedMenu.keys) {
      final currentItems = _categorizedMenu[category]!;
      final originalItems = _originalMenuData[category]!;
      if (currentItems.length != originalItems.length) return true;
      if (Set.from(currentItems) != Set.from(originalItems)) return true;
    }
    return false;
  }

  Future<void> saveChanges() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _menuService.saveMenuItems(_categorizedMenu, storeId);
      await loadMenuData();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void addCategory(String categoryName) {
    if (!_categories.contains(categoryName)) {
      _categories.add(categoryName);
      _categorizedMenu[categoryName] = [];
      notifyListeners();
    }
  }

  void editCategory(String oldName, String newName) {
    if (_categories.contains(oldName) && !_categories.contains(newName)) {
      final index = _categories.indexOf(oldName);
      _categories[index] = newName;
      final menuList = _categorizedMenu.remove(oldName) ?? [];
      _categorizedMenu[newName] =
          menuList.map((item) => item.copyWith(category: newName)).toList();
      _menuItems = _menuItems
          .map((item) => item.category == oldName
              ? item.copyWith(category: newName)
              : item)
          .toList();
      notifyListeners();
    }
  }

  void deleteCategory(int index) {
    final category = _categories[index];
    _menuItems.removeWhere((item) => item.category == category);
    _categories.removeAt(index);
    _categorizedMenu.remove(category);
    notifyListeners();
  }

  void addMenu(MenuListItem newMenu) {
    _menuItems.add(newMenu);
    _updateAndBackupCategorizedMenu();
  }

  void editMenu(MenuListItem updatedMenu) {
    final index = _menuItems.indexWhere((item) =>
        item.id == updatedMenu.id || item.menuId == updatedMenu.menuId);
    if (index != -1) {
      _menuItems[index] = updatedMenu;
      _updateAndBackupCategorizedMenu();
    }
  }

  void deleteMenu(String category, int menuIndex) {
    final menuItem = _categorizedMenu[category]![menuIndex];
    final index = _menuItems.indexWhere(
        (item) => item.id == menuItem.id && item.menuId == menuItem.menuId);
    if (index != -1) {
      _menuItems[index] =
          menuItem.copyWith(menuStatus: 'disable', updatedAt: DateTime.now());
      _updateAndBackupCategorizedMenu();
    }
  }

  void deleteAllMenus() {
    _menuItems = _menuItems
        .map((item) =>
            item.copyWith(menuStatus: 'disable', updatedAt: DateTime.now()))
        .toList();
    _updateAndBackupCategorizedMenu();
  }
}
