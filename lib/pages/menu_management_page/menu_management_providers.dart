// メニュー管理画面の状態管理 (Riverpod)
//
// Provider(MVVM)からの移行。他ページから参照されないページローカル状態。
//
// 既存ViewModelの挙動をそのまま踏襲する点:
// - addCategory はサーバー呼び出しなしでローカルにのみ空カテゴリを追加する
//   (categoriesが常にitemsから完全導出されるわけではなく、addCategory直後は
//    一時的に独立している。他の操作でrecomputeが走ると空カテゴリは消える —
//    これは仕様というより既存実装の特性だが、アーキテクチャ移行のみが目的のため
//    挙動をそのまま保持する)
// - editMenu はローカル即時反映 + 1秒デバウンスでサーバーへ反映する
import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yoyaku_mate_provider/models/menu_list.dart';
import 'package:yoyaku_mate_provider/services/menu_service.dart';

part 'menu_management_providers.g.dart';

// 保存ステータス (SaveStatusIndicator表示用)
enum SaveStatus { saved, saving, error }

@riverpod
MenuService menuService(Ref ref) => MenuService();

// カテゴリ/メニュー一覧の状態。
// categorizedMenu/categoriesはitemsから再計算されるのが基本だが、
// addCategoryは例外的にローカルのみで独立した空カテゴリを持てる (既存挙動)
class MenuManagementData {
  final List<MenuListItem> items;
  final List<String> categories;
  final Map<String, List<MenuListItem>> categorizedMenu;

  const MenuManagementData({
    required this.items,
    required this.categories,
    required this.categorizedMenu,
  });

  // itemsからcategorizedMenu/categoriesを完全に再計算する
  // (既存の _updateCategorizedMenu と同じロジック・同じタイミングで使用)
  factory MenuManagementData.recompute(List<MenuListItem> items) {
    final map = <String, List<MenuListItem>>{};
    for (final item in items) {
      final category = item.category.isNotEmpty ? item.category : '未分類';
      (map[category] ??= []).add(item);
    }
    return MenuManagementData(
      items: items,
      categories: map.keys.toList(),
      categorizedMenu: map,
    );
  }
}

@riverpod
class MenuItemsNotifier extends _$MenuItemsNotifier {
  Timer? _autoSaveTimer;

  @override
  Future<MenuManagementData> build({required String storeId}) async {
    ref.onDispose(() => _autoSaveTimer?.cancel());
    final service = ref.watch(menuServiceProvider);
    final items = await service.fetchMenuItems(storeId);
    return MenuManagementData.recompute(items);
  }

  void _setSaveStatus(SaveStatus status) {
    ref.read(menuSaveStatusProvider.notifier).update(status);
  }

  // カテゴリ追加 - ローカルのみ即時反映 (サーバー呼び出しなし、既存挙動)
  void addCategory(String categoryName) {
    final current = state.valueOrNull;
    if (current == null || current.categories.contains(categoryName)) return;

    final newCategorized =
        Map<String, List<MenuListItem>>.from(current.categorizedMenu);
    newCategorized[categoryName] = [];
    state = AsyncData(MenuManagementData(
      items: current.items,
      categories: [...current.categories, categoryName],
      categorizedMenu: newCategorized,
    ));
  }

  Future<void> editCategory(
      String storeId, String oldName, String newName) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.categories.contains(oldName) ||
        current.categories.contains(newName)) {
      return;
    }

    _setSaveStatus(SaveStatus.saving);
    try {
      final menuList = current.categorizedMenu[oldName] ?? [];
      // 1回のAPI呼び出しで全メニューのカテゴリを更新 (N+1問題解決)
      if (menuList.isNotEmpty) {
        await ref
            .read(menuServiceProvider)
            .bulkUpdateCategory(storeId, oldName, newName);
      }

      final newCategories = [...current.categories];
      newCategories[newCategories.indexOf(oldName)] = newName;

      final renamedItems =
          menuList.map((item) => item.copyWith(category: newName)).toList();
      final newCategorized =
          Map<String, List<MenuListItem>>.from(current.categorizedMenu)
            ..remove(oldName)
            ..[newName] = renamedItems;

      final newItems = current.items
          .map((item) =>
              item.category == oldName ? item.copyWith(category: newName) : item)
          .toList();

      state = AsyncData(MenuManagementData(
        items: newItems,
        categories: newCategories,
        categorizedMenu: newCategorized,
      ));
      _setSaveStatus(SaveStatus.saved);
    } catch (e) {
      _setSaveStatus(SaveStatus.error);
      rethrow;
    }
  }

  // カテゴリ削除 - 即時サーバーに反映
  Future<void> deleteCategory(String storeId, int index) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final category = current.categories[index];
    final menuList = current.categorizedMenu[category] ?? [];

    _setSaveStatus(SaveStatus.saving);
    try {
      // 1回のAPI呼び出しで関連全メニューを非表示 (N+1問題解決)
      if (menuList.isNotEmpty) {
        await ref.read(menuServiceProvider).bulkDeleteCategory(storeId, category);
      }

      final newItems =
          current.items.where((item) => item.category != category).toList();
      final newCategories = [...current.categories]..removeAt(index);
      final newCategorized =
          Map<String, List<MenuListItem>>.from(current.categorizedMenu)
            ..remove(category);

      state = AsyncData(MenuManagementData(
        items: newItems,
        categories: newCategories,
        categorizedMenu: newCategorized,
      ));
      _setSaveStatus(SaveStatus.saved);
    } catch (e) {
      _setSaveStatus(SaveStatus.error);
      rethrow;
    }
  }

  // 新規メニュー追加。呼び出し元がsavedMenu(nullなら失敗)を見て後続処理(画像アップロード等)を行う
  Future<MenuListItem?> addMenu(String storeId, MenuListItem newMenu) async {
    final current = state.valueOrNull;
    if (current == null) return null;

    _setSaveStatus(SaveStatus.saving);
    try {
      final savedMenu =
          await ref.read(menuServiceProvider).createSingleMenu(newMenu, storeId);

      state = AsyncData(MenuManagementData.recompute([...current.items, savedMenu]));
      _setSaveStatus(SaveStatus.saved);
      return savedMenu;
    } catch (e) {
      _setSaveStatus(SaveStatus.error);
      return null;
    }
  }

  // イメージ付きメニュー更新
  Future<void> updateMenuWithImage(MenuListItem menuData, File imageFile) async {
    final current = state.valueOrNull;
    if (current == null) return;

    _setSaveStatus(SaveStatus.saving);
    try {
      final uploadedMenu =
          await ref.read(menuServiceProvider).uploadMenuImage(menuData.id, imageFile);

      final finalUpdatedMenu = uploadedMenu.copyWith(
        title: menuData.title,
        description: menuData.description,
        price: menuData.price,
        category: menuData.category,
        titleTranslations: menuData.titleTranslations,
        descriptionTranslations: menuData.descriptionTranslations,
      );

      final index =
          current.items.indexWhere((item) => item.id == finalUpdatedMenu.id);
      if (index != -1) {
        final newItems = [...current.items];
        newItems[index] = finalUpdatedMenu;
        state = AsyncData(MenuManagementData.recompute(newItems));
      }
      _setSaveStatus(SaveStatus.saved);
    } catch (e) {
      _setSaveStatus(SaveStatus.error);
      rethrow;
    }
  }

  // メニュー編集 (テキスト情報のみ)。ローカル即時反映 + 1秒デバウンスでサーバー反映
  void editMenu(String storeId, MenuListItem updatedMenu) {
    final current = state.valueOrNull;
    if (current == null) return;

    final index = current.items.indexWhere((item) =>
        (item.id.isNotEmpty && item.id == updatedMenu.id) ||
        (item.id.isEmpty && item.menuId == updatedMenu.menuId));

    if (index != -1) {
      final newItems = [...current.items];
      newItems[index] = updatedMenu;
      state = AsyncData(MenuManagementData.recompute(newItems));
    }

    _autoSave(updatedMenu);
  }

  void _autoSave(MenuListItem menu) {
    _autoSaveTimer?.cancel();
    _setSaveStatus(SaveStatus.saving);

    _autoSaveTimer = Timer(const Duration(seconds: 1), () async {
      try {
        await ref.read(menuServiceProvider).updateSingleMenu(menu);
        _setSaveStatus(SaveStatus.saved);
      } catch (e) {
        _setSaveStatus(SaveStatus.error);
      }
    });
  }

  // メニュー削除 (状態変更)
  Future<void> deleteMenu(String storeId, String category, int menuIndex) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final menuItem = current.categorizedMenu[category]![menuIndex];

    _setSaveStatus(SaveStatus.saving);
    try {
      await ref.read(menuServiceProvider).deleteSingleMenu(menuItem.id, storeId);

      final newItems =
          current.items.where((item) => item.id != menuItem.id).toList();
      state = AsyncData(MenuManagementData.recompute(newItems));
      _setSaveStatus(SaveStatus.saved);
    } catch (e) {
      _setSaveStatus(SaveStatus.error);
      rethrow;
    }
  }

  // 全体メニュー削除 (状態変更)
  Future<void> deleteAllMenus(String storeId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    _setSaveStatus(SaveStatus.saving);
    try {
      // 1回のAPI呼び出しで全メニュー非表示 (N+1問題解決)
      final hasActiveMenus =
          current.items.any((item) => item.menuStatus != 'disable');
      if (hasActiveMenus) {
        await ref.read(menuServiceProvider).bulkDeleteAllMenus(storeId);
      }

      state = const AsyncData(
          MenuManagementData(items: [], categories: [], categorizedMenu: {}));
      _setSaveStatus(SaveStatus.saved);
    } catch (e) {
      _setSaveStatus(SaveStatus.error);
      rethrow;
    }
  }
}

// 保存状態バッジ用。メニュー一覧本体と分離しているため、バッジだけ独立して再描画される
@riverpod
class MenuSaveStatus extends _$MenuSaveStatus {
  @override
  SaveStatus build() => SaveStatus.saved;

  void update(SaveStatus status) => state = status;
}
