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
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yoyaku_mate_provider/models/menu_list.dart';
import 'package:yoyaku_mate_provider/services/menu_service.dart';
import 'package:yoyaku_mate_provider/services/translation_service.dart';

part 'menu_management_providers.g.dart';

// 保存ステータス (SaveStatusIndicator表示用)
enum SaveStatus { saved, saving, error }

// 1回の翻訳リクエストに含めるメニュー件数。
// 全件を1回で投げるとGeminiの出力上限で末尾が欠落するため分割する
const int _backfillChunkSize = 15;

// 一括翻訳(バックフィル)で実際に翻訳が必要な対象。
// 確認ダイアログの件数表示と実処理で同じ判定を使い、
// 既に翻訳済みの項目に翻訳APIを呼んで課金が発生するのを防ぐ
class BackfillPlan {
  // タイトル/説明の翻訳が不足しているメニュー
  final List<MenuListItem> pendingItems;
  // 翻訳が不足しているカテゴリー名
  final List<String> pendingCategories;
  // サーバー更新が必要になりうるメニュー。
  // カテゴリー翻訳は各メニュー文書に載るため、翻訳が増えたカテゴリーに属する
  // メニューは(自身の翻訳が揃っていても)更新対象になる
  final List<MenuListItem> patchTargets;

  const BackfillPlan({
    required this.pendingItems,
    required this.pendingCategories,
    required this.patchTargets,
  });

  static const BackfillPlan empty = BackfillPlan(
    pendingItems: [],
    pendingCategories: [],
    patchTargets: [],
  );

  bool get isEmpty => pendingItems.isEmpty && pendingCategories.isEmpty;
}

// 一括翻訳(バックフィル)の結果。
// 再試行後も翻訳が埋まらなかった項目を呼び出し元に伝え、
// 実際には未翻訳なのに成功トーストだけ出る状態を防ぐ
class BackfillResult {
  final int translatedMenuCount;
  final int missingMenuCount;
  final List<String> missingCategories;

  const BackfillResult({
    required this.translatedMenuCount,
    required this.missingMenuCount,
    required this.missingCategories,
  });

  static const BackfillResult empty = BackfillResult(
    translatedMenuCount: 0,
    missingMenuCount: 0,
    missingCategories: [],
  );

  bool get isComplete => missingMenuCount == 0 && missingCategories.isEmpty;
}

@riverpod
MenuService menuService(Ref ref) => MenuService();

// カテゴリ/メニュー一覧の状態。
// categorizedMenu/categoriesはitemsから再計算されるのが基本だが、
// addCategoryは例外的にローカルのみで独立した空カテゴリを持てる (既存挙動)
class MenuManagementData {
  final List<MenuListItem> items;
  final List<String> categories;
  final Map<String, List<MenuListItem>> categorizedMenu;
  final Map<String, Map<String, String>> categoryTranslations;

  const MenuManagementData({
    required this.items,
    required this.categories,
    required this.categorizedMenu,
    this.categoryTranslations = const {},
  });

  // itemsからcategorizedMenu/categoriesを完全に再計算する
  // (既存の _updateCategorizedMenu と同じロジック・同じタイミングで使用)
  factory MenuManagementData.recompute(List<MenuListItem> items) {
    final map = <String, List<MenuListItem>>{};
    final translations = <String, Map<String, String>>{};
    for (final item in items) {
      final category = item.category.isNotEmpty ? item.category : '未分類';
      (map[category] ??= []).add(item);
      if (item.categoryTranslations.isNotEmpty) {
        translations[category] = item.categoryTranslations;
      }
    }
    return MenuManagementData(
      items: items,
      categories: map.keys.toList(),
      categorizedMenu: map,
      categoryTranslations: translations,
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
  void addCategory(String categoryName,
      {Map<String, String> translations = const {}}) {
    final current = state.valueOrNull;
    if (current == null || current.categories.contains(categoryName)) return;

    final newCategorized =
        Map<String, List<MenuListItem>>.from(current.categorizedMenu);
    newCategorized[categoryName] = [];
    final newTranslations =
        Map<String, Map<String, String>>.from(current.categoryTranslations);
    if (translations.isNotEmpty) newTranslations[categoryName] = translations;

    state = AsyncData(MenuManagementData(
      items: current.items,
      categories: [...current.categories, categoryName],
      categorizedMenu: newCategorized,
      categoryTranslations: newTranslations,
    ));
  }

  Future<void> editCategory(
      String storeId, String oldName, String newName,
      {Map<String, String> translations = const {}}) async {
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
        await ref.read(menuServiceProvider).bulkUpdateCategory(
            storeId, oldName, newName,
            categoryTranslations: translations);
      }

      final newCategories = [...current.categories];
      newCategories[newCategories.indexOf(oldName)] = newName;

      final renamedItems = menuList
          .map((item) => item.copyWith(
              category: newName, categoryTranslations: translations))
          .toList();
      final newCategorized =
          Map<String, List<MenuListItem>>.from(current.categorizedMenu)
            ..remove(oldName)
            ..[newName] = renamedItems;

      final newItems = current.items
          .map((item) => item.category == oldName
              ? item.copyWith(
                  category: newName, categoryTranslations: translations)
              : item)
          .toList();

      final newTranslations =
          Map<String, Map<String, String>>.from(current.categoryTranslations)
            ..remove(oldName);
      if (translations.isNotEmpty) newTranslations[newName] = translations;

      state = AsyncData(MenuManagementData(
        items: newItems,
        categories: newCategories,
        categorizedMenu: newCategorized,
        categoryTranslations: newTranslations,
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
      final newTranslations =
          Map<String, Map<String, String>>.from(current.categoryTranslations)
            ..remove(category);

      state = AsyncData(MenuManagementData(
        items: newItems,
        categories: newCategories,
        categorizedMenu: newCategorized,
        categoryTranslations: newTranslations,
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

  // 指定言語について、翻訳が不足している項目を洗い出す (API呼び出しなし)。
  // 確認ダイアログで「実際に翻訳が必要な件数」を出すために使う
  Future<BackfillPlan> planBackfillTranslations(List<String> languages) async {
    if (languages.isEmpty) return BackfillPlan.empty;
    // - state.valueOrNullだとautoDispose後に再生成された直後のnullを
    //   拾ってしまい、メニュー未ロード時に何も対象がない扱いになる。
    //   awaitで確実に最新データをロードする
    final current = await future;
    return _buildPlan(current, languages);
  }

  // 翻訳が不足している項目について、翻訳しサーバーに反映する。
  // 「設定 > 店舗 > 多言語対応」で言語を追加したときにのみ、ユーザーの明示的な確認を
  // 経て呼ばれる操作(自動では走らせない。翻訳API呼び出しのコストが発生するため)。
  //
  // 既に翻訳済みの(メニュー × 言語)は要求自体から除外する。
  // これにより、言語をOFF→ONと切り替えても翻訳済みのものは再課金されない
  //
  // onProgress: (完了ステップ数, 全ステップ数)。呼び出し元の進捗ダイアログ表示用。
  Future<BackfillResult> backfillTranslations(
      String storeId, List<String> languages,
      {void Function(int done, int total)? onProgress}) async {
    if (languages.isEmpty) return BackfillResult.empty;
    final current = await future;
    final plan = _buildPlan(current, languages);
    if (plan.isEmpty) return BackfillResult.empty;

    // 全ステップ数 = 翻訳リクエスト回数(カテゴリー1回 + メニューのチャンク数) + PATCH対象件数
    final chunkCount = (plan.pendingItems.length / _backfillChunkSize).ceil();
    final totalSteps = chunkCount +
        (plan.pendingCategories.isEmpty ? 0 : 1) +
        plan.patchTargets.length;
    var doneSteps = 0;
    void tick() => onProgress?.call(++doneSteps, totalSteps);

    _setSaveStatus(SaveStatus.saving);
    try {
      // --- カテゴリー名の翻訳 (不足しているカテゴリー・言語のみ) ---
      // リクエストのキーは必ずASCII(c_0, c_1...)にする。カテゴリー名をそのまま
      // キーにすると、Geminiがキーに含まれる日本語まで翻訳して返してくるため
      // 結果を引き当てられず、カテゴリーだけ未翻訳のまま残っていた
      final newCategoryTranslations = <String, Map<String, String>>{};
      final missingCategories = <String>[];
      if (plan.pendingCategories.isNotEmpty) {
        final categoryTexts = <String, String>{};
        final categoryLanguages = <String>{};
        for (var i = 0; i < plan.pendingCategories.length; i++) {
          final cat = plan.pendingCategories[i];
          categoryTexts['c_$i'] = cat;
          categoryLanguages.addAll(_missingLanguagesForCategory(
              current.categoryTranslations[cat], languages));
        }
        final result =
            await _translateWithRetry(categoryTexts, categoryLanguages.toList());
        tick();

        for (var i = 0; i < plan.pendingCategories.length; i++) {
          final cat = plan.pendingCategories[i];
          final existing = current.categoryTranslations[cat];
          // 既存の翻訳はそのまま保持し、不足している言語だけを埋める
          final merged = Map<String, String>.from(existing ?? {});
          for (final lang in _missingLanguagesForCategory(existing, languages)) {
            final translated = result[lang]?['c_$i'];
            if (translated != null && translated.isNotEmpty) {
              merged[lang] = translated;
            }
          }
          newCategoryTranslations[cat] = merged;
          if (_missingLanguagesForCategory(merged, languages).isNotEmpty) {
            missingCategories.add(cat);
          }
        }
      }

      // --- メニューの翻訳 (不足しているメニュー・言語のみ) ---
      // 全件を1回で投げるとGeminiの出力上限で末尾が丸ごと欠落しうるため、
      // 一定件数ごとに分割して呼び出す
      final pending = plan.pendingItems;
      final translatedById = <String, MenuListItem>{};
      final missingMenuIds = <String>{};

      for (var start = 0; start < pending.length; start += _backfillChunkSize) {
        final end = math.min(start + _backfillChunkSize, pending.length);
        final chunk = pending.sublist(start, end);

        final texts = <String, String>{};
        final chunkLanguages = <String>{};
        final missingByIndex = <int, List<String>>{};
        for (var i = 0; i < chunk.length; i++) {
          final item = chunk[i];
          final missing = _missingLanguagesForItem(item, languages);
          missingByIndex[i] = missing;
          chunkLanguages.addAll(missing);
          if (item.title.isNotEmpty) texts['t_$i'] = item.title;
          if (item.description.isNotEmpty) texts['d_$i'] = item.description;
        }

        final result = (texts.isEmpty || chunkLanguages.isEmpty)
            ? const <String, Map<String, String>>{}
            : await _translateWithRetry(texts, chunkLanguages.toList());
        tick();

        for (var i = 0; i < chunk.length; i++) {
          final item = chunk[i];
          final newTitleTranslations =
              Map<String, String>.from(item.titleTranslations);
          final newDescTranslations =
              Map<String, String>.from(item.descriptionTranslations);

          // 既に翻訳がある言語には触れず、不足している言語だけを埋める
          for (final lang in missingByIndex[i]!) {
            final translatedTitle = result[lang]?['t_$i'];
            if (translatedTitle != null && translatedTitle.isNotEmpty) {
              newTitleTranslations[lang] = translatedTitle;
            }
            final translatedDesc = result[lang]?['d_$i'];
            if (translatedDesc != null && translatedDesc.isNotEmpty) {
              newDescTranslations[lang] = translatedDesc;
            }
          }

          final translated = item.copyWith(
            titleTranslations: newTitleTranslations,
            descriptionTranslations: newDescTranslations,
          );
          translatedById[item.id] = translated;
          // 再試行後も埋まらなかったものは呼び出し元に報告する
          if (_missingLanguagesForItem(translated, languages).isNotEmpty) {
            missingMenuIds.add(item.id);
          }
        }
      }

      // --- サーバー反映 (実際に値が変わったメニューのみPATCH) ---
      // メニューごとの更新エンドポイントしか存在しないため、ここは対象件数分のPATCHになる
      // (category_translationsも同じPATCHに含まれるため、カテゴリー用の追加API呼び出しは不要)
      final patchTargetIds = plan.patchTargets.map((item) => item.id).toSet();
      final newItems = <MenuListItem>[];
      var savedCount = 0;

      for (final item in current.items) {
        final translated = translatedById[item.id] ?? item;
        final updated = translated.copyWith(
          // recomputeと同じキー(空カテゴリーは'未分類')で引かないと、
          // 未分類のメニューにカテゴリー翻訳が反映されない
          categoryTranslations: newCategoryTranslations[_categoryKeyOf(item)] ??
              item.categoryTranslations,
        );
        newItems.add(updated);

        if (!patchTargetIds.contains(item.id)) continue;
        if (_hasSameTranslations(item, updated)) {
          // 翻訳が1件も増えなかった (APIが埋められなかった) 場合は保存しない
          tick();
          continue;
        }
        await ref.read(menuServiceProvider).updateSingleMenu(updated);
        savedCount++;
        tick();
      }

      state = AsyncData(MenuManagementData.recompute(newItems));
      _setSaveStatus(SaveStatus.saved);
      return BackfillResult(
        translatedMenuCount: savedCount,
        missingMenuCount: missingMenuIds.length,
        missingCategories: missingCategories,
      );
    } catch (e) {
      _setSaveStatus(SaveStatus.error);
      rethrow;
    }
  }

  // 翻訳が不足している項目を洗い出す。
  // 「翻訳が存在する = 現在の原文に対する翻訳」という前提で判定する。
  // (原文が変わったときは編集ダイアログ側で全言語の翻訳を破棄しているため、
  //  古い原文の翻訳が「翻訳済み」と誤判定されることはない)
  BackfillPlan _buildPlan(MenuManagementData data, List<String> languages) {
    final pendingItems = data.items
        .where((item) => _missingLanguagesForItem(item, languages).isNotEmpty)
        .toList();
    // カテゴリー翻訳はメニュー文書のcategory_translationsとして保存されるため、
    // メニューが0件のカテゴリー(addCategoryでローカル追加しただけの状態)は
    // 翻訳しても保存先が無く消える。対象に含めると毎回対象として残り、
    // 翻訳APIを呼び続けることになるので除外する
    final pendingCategories = data.categories
        .where((cat) =>
            (data.categorizedMenu[cat]?.isNotEmpty ?? false) &&
            _missingLanguagesForCategory(
                    data.categoryTranslations[cat], languages)
                .isNotEmpty)
        .toList();

    final pendingItemIds = pendingItems.map((item) => item.id).toSet();
    final patchTargets = data.items
        .where((item) =>
            pendingItemIds.contains(item.id) ||
            pendingCategories.contains(_categoryKeyOf(item)))
        .toList();

    return BackfillPlan(
      pendingItems: pendingItems,
      pendingCategories: pendingCategories,
      patchTargets: patchTargets,
    );
  }

  // そのメニューで翻訳が欠けている言語 (空文字は未翻訳扱い)
  List<String> _missingLanguagesForItem(
      MenuListItem item, List<String> languages) {
    return languages.where((lang) {
      if (item.title.isNotEmpty && (item.titleTranslations[lang] ?? '').isEmpty) {
        return true;
      }
      if (item.description.isNotEmpty &&
          (item.descriptionTranslations[lang] ?? '').isEmpty) {
        return true;
      }
      return false;
    }).toList();
  }

  // そのカテゴリーで翻訳が欠けている言語
  List<String> _missingLanguagesForCategory(
      Map<String, String>? translations, List<String> languages) {
    return languages
        .where((lang) => (translations?[lang] ?? '').isEmpty)
        .toList();
  }

  // 不要なPATCHを避けるための比較
  bool _hasSameTranslations(MenuListItem a, MenuListItem b) =>
      mapEquals(a.titleTranslations, b.titleTranslations) &&
      mapEquals(a.descriptionTranslations, b.descriptionTranslations) &&
      mapEquals(a.categoryTranslations, b.categoryTranslations);

  // recompute() がカテゴリーキーとして使う値 (空カテゴリーは'未分類'に寄せる)
  String _categoryKeyOf(MenuListItem item) =>
      item.category.isNotEmpty ? item.category : '未分類';

  // 翻訳結果を検証し、欠けている項目だけを1回再試行してマージする。
  // Geminiはキーを取りこぼしたり出力が途中で切れたりすることがあり、
  // 検証なしで採用すると未翻訳のまま「完了」扱いになってしまう
  Future<Map<String, Map<String, String>>> _translateWithRetry(
      Map<String, String> texts, List<String> languages) async {
    final merged = await TranslationService()
        .translateToMultipleLanguages(texts, languages, smartMenuMode: true);

    final missingLanguages = <String>[];
    final missingKeys = <String>{};
    for (final lang in languages) {
      final translated = merged[lang] ?? const <String, String>{};
      final lacking = texts.keys
          .where((key) => (translated[key] ?? '').isEmpty)
          .toList();
      if (lacking.isNotEmpty) {
        missingLanguages.add(lang);
        missingKeys.addAll(lacking);
      }
    }
    if (missingKeys.isEmpty) return merged;

    try {
      final retryTexts = <String, String>{
        for (final key in missingKeys) key: texts[key]!,
      };
      final retried = await TranslationService().translateToMultipleLanguages(
          retryTexts, missingLanguages,
          smartMenuMode: true);
      retried.forEach((lang, transMap) {
        final target = merged.putIfAbsent(lang, () => <String, String>{});
        transMap.forEach((key, value) {
          if (value.isNotEmpty) target[key] = value;
        });
      });
    } catch (e) {
      // 再試行の失敗で1回目の成功分まで捨てないよう、ここでは握り潰す。
      // 埋まらなかった項目は呼び出し元にBackfillResultとして報告される
      debugPrint('Backfill retry failed: $e');
    }
    return merged;
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
