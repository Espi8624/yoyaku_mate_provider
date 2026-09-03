import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yoyaku_mate_provider/pages/menu_management_page/widgets/panels/action_button_panel_mobile.dart';
import '../../models/menu_list.dart';
import '../../services/api_exception.dart';
import 'menu_management_providers.dart';

import '../../widgets/common_dialogs/confirmation_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';
import '../../widgets/common_widgets/loading_indicator.dart';
import 'widgets/dialogs/category_form_dialog.dart';
import 'widgets/dialogs/menu_form_dialog.dart';
import '../../widgets/common_dialogs/base_dialog.dart';
import 'widgets/panels/action_buttons_panel.dart';
import 'widgets/panels/menu_list_panel.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

// 更新の成功/失敗は共有状態ではなく、呼び出し直後にtry/catchで即時Toast表示する
String _describeError(Object error) {
  if (error is ApiException) return error.message;
  return '予期しないエラーが発生しました: $error';
}

class MenuManagementScreen extends StatelessWidget {
  final String storeId;
  const MenuManagementScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return _MenuManagementView(storeId: storeId);
  }
}

class _MenuManagementView extends ConsumerStatefulWidget {
  final String storeId;
  const _MenuManagementView({required this.storeId});

  @override
  ConsumerState<_MenuManagementView> createState() =>
      _MenuManagementViewState();
}

class _MenuManagementViewState extends ConsumerState<_MenuManagementView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // データロード前はカテゴリー数0でTabControllerを生成しておき、
    // 実データ到着時にref.listen(build内)で作り直す (既存挙動を踏襲)
    _tabController = TabController(length: 0, vsync: this);
    _addTabListener();
  }

  // Listener 追加ロジック
  void _addTabListener() {
    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.animation?.value == _tabController.index.toDouble()) {
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  MenuManagementData? get _data => ref
      .read(menuItemsNotifierProvider(storeId: widget.storeId))
      .valueOrNull;
  List<String> get _categories => _data?.categories ?? const <String>[];
  Map<String, List<MenuListItem>> get _categorizedMenu =>
      _data?.categorizedMenu ?? const {};

  Future<void> _showAddCategoryDialog() async {
    final newCategory = await showDialog<String>(
      context: context,
      builder: (_) => CategoryFormDialog(existingCategories: _categories),
    );
    if (newCategory != null) {
      ref
          .read(menuItemsNotifierProvider(storeId: widget.storeId).notifier)
          .addCategory(newCategory);
      _tabController.animateTo(_tabController.length - 1);
    }
  }

  Future<void> _showEditCategoryDialog(int index) async {
    final categories = _categories;
    final oldCategory = categories[index];
    final newCategory = await showDialog<String>(
      context: context,
      builder: (_) => CategoryFormDialog(
          initialValue: oldCategory, existingCategories: categories),
    );
    if (newCategory == 'DELETE_ACTION') {
      _showDeleteCategoryDialog(index);
    } else if (newCategory != null && newCategory != oldCategory) {
      try {
        await ref
            .read(menuItemsNotifierProvider(storeId: widget.storeId).notifier)
            .editCategory(widget.storeId, oldCategory, newCategory);
      } catch (e) {
        if (!mounted) return;
        ToastWidget.show(context, _describeError(e), type: ToastType.error);
      }
    }
  }

  Future<void> _showDeleteCategoryDialog(int index) async {
    final confirmed = await showConfirmationDialog(
        context: context,
        title: 'カテゴリー削除',
        content: 'このカテゴリーと含まれる全てのメニューを削除しますか？');
    if (confirmed == true) {
      if (!mounted) return;
      try {
        await ref
            .read(menuItemsNotifierProvider(storeId: widget.storeId).notifier)
            .deleteCategory(widget.storeId, index);
        if (!mounted) return;
        ToastWidget.show(context, 'カテゴリーが削除されました', type: ToastType.success);
      } catch (e) {
        if (!mounted) return;
        ToastWidget.show(context, _describeError(e), type: ToastType.error);
      }
    }
  }

  Future<void> _showAddMenuDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => MenuFormDialog(
          storeId: widget.storeId,
          category: _categories[_tabController.index]),
    );

    if (result != null) {
      final newMenu = result['menu'] as MenuListItem;
      final imageBytes = result['imageFile'] as Uint8List?;

      // メニュー保存
      final savedMenu = await ref
          .read(menuItemsNotifierProvider(storeId: widget.storeId).notifier)
          .addMenu(widget.storeId, newMenu);

      if (!mounted) return;

      if (savedMenu == null) {
        ToastWidget.show(context, 'メニュー追加に失敗しました', type: ToastType.error);
        return;
      }

      // イメージが選択されていればアップロード
      if (imageBytes != null && savedMenu.id.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageFile = await File(path).writeAsBytes(imageBytes);

        try {
          await ref
              .read(
                  menuItemsNotifierProvider(storeId: widget.storeId).notifier)
              .updateMenuWithImage(savedMenu, imageFile);
        } catch (e) {
          if (!mounted) return;
          ToastWidget.show(context, _describeError(e), type: ToastType.error);
          return;
        }
      }

      if (!mounted) return;
      ToastWidget.show(context, 'メニューが追加されました', type: ToastType.success);
    }
  }

  Future<void> _showEditMenuDialog(int categoryIndex, int menuIndex) async {
    final category = _categories[categoryIndex];
    final menuItem = _categorizedMenu[category]![menuIndex];

    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => MenuFormDialog(
          menuItem: menuItem, storeId: widget.storeId, category: category),
    );

    if (result == 'DELETE_ACTION') {
      _showDeleteMenuDialog(categoryIndex, menuIndex);
      return;
    }

    if (result != null && result is Map<String, dynamic>) {
      final updatedMenu = result['menu'] as MenuListItem;
      final imageBytes = result['imageFile'] as Uint8List?;
      final imageRemoved = result['imageRemoved'] as bool? ?? false;

      final notifier = ref
          .read(menuItemsNotifierProvider(storeId: widget.storeId).notifier);

      if (imageBytes != null) {
        // 新しいイメージ選択 → アップロード
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageFile = await File(path).writeAsBytes(imageBytes);
        try {
          await notifier.updateMenuWithImage(updatedMenu, imageFile);
        } catch (e) {
          if (!mounted) return;
          ToastWidget.show(context, _describeError(e), type: ToastType.error);
        }
      } else if (imageRemoved) {
        // イメージ削除　→ 空の文字列で更新
        final menuWithoutImage = updatedMenu.copyWith(menuImageUrl: '');
        notifier.editMenu(widget.storeId, menuWithoutImage);
        if (!mounted) return;
        ToastWidget.show(context, '画像が削除されました', type: ToastType.success);
      } else {
        // テキスト情報のみ更新
        notifier.editMenu(widget.storeId, updatedMenu);
      }
    }
  }

  Future<void> _showDeleteMenuDialog(int categoryIndex, int menuIndex) async {
    final confirmed = await showConfirmationDialog(
        context: context, title: 'メニュー削除', content: '本当にこのメニューを削除しますか？');
    if (confirmed == true) {
      final category = _categories[categoryIndex];
      try {
        await ref
            .read(menuItemsNotifierProvider(storeId: widget.storeId).notifier)
            .deleteMenu(widget.storeId, category, menuIndex);
        if (!mounted) return;
        ToastWidget.show(context, 'メニューが削除されました', type: ToastType.success);
      } catch (e) {
        if (!mounted) return;
        ToastWidget.show(context, _describeError(e), type: ToastType.error);
      }
    }
  }

  Future<void> _showDeleteAllMenusDialog() async {
    final confirmed = await showConfirmationDialog(
        context: context,
        title: 'メニュー初期化',
        content: '全てのメニューを削除状態にしますか？\nこの操作は「保存」を押すと確定されます。');
    if (confirmed == true) {
      try {
        await ref
            .read(menuItemsNotifierProvider(storeId: widget.storeId).notifier)
            .deleteAllMenus(widget.storeId);
        if (!mounted) return;
        ToastWidget.show(context, '全てのメニューが削除状態になりました', type: ToastType.info);
      } catch (e) {
        if (!mounted) return;
        ToastWidget.show(context, _describeError(e), type: ToastType.error);
      }
    }
  }

  Future<void> _showLanguageSelectionDialog() async {
    final selectedLang = await showDialog<String>(
      context: context,
      builder: (context) {
        return BaseDialog(
          title: '出力言語選択',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Independent Japanese Option
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: () => Navigator.pop(context, 'Japanese'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: const Text(
                      '日本語',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24), // Distinct gap
              // Other Languages Group
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ...{
                      'en': '英語',
                      'ko': '韓国語',
                      'zh': '中国語',
                      'zh-TW': '中国語 (台湾)',
                      'es': 'スペイン語',
                      'fr': 'フランス語',
                      'de': 'ドイツ語',
                      'it': 'イタリア語',
                      'ru': 'ロシア語',
                      'pt': 'ポルトガル語',
                      'ar': 'アラビア語',
                    }.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final e = entry.value;
                      // Dynamic check for last item
                      final isLast = index == 10; // Total 11 items (0-10)

                      return Column(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context, e.key),
                            borderRadius: isLast
                                ? const BorderRadius.vertical(
                                    bottom: Radius.circular(8))
                                : (index == 0
                                    ? const BorderRadius.vertical(
                                        top: Radius.circular(8))
                                    : BorderRadius.zero),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
                              child: Text(
                                e.value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          if (!isLast)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.border,
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedLang != null) {
      // 言語選択後にカテゴリー選択ダイアログを表示
      await _showCategorySelectionDialog(selectedLang);
    }
  }

  Future<void> _showCategorySelectionDialog(String selectedLang) async {
    final categories = _categories;
    final selectedCategory = await showDialog<String>(
      context: context,
      builder: (context) {
        return BaseDialog(
          title: '出力カテゴリー選択',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "すべて出力" Option
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: () => Navigator.pop(context, 'ALL_CATEGORIES'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: const Text(
                      'すべて出力',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Categories List
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ...categories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      final isLast = index == categories.length - 1;

                      return Column(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context, category),
                            borderRadius: isLast
                                ? const BorderRadius.vertical(
                                    bottom: Radius.circular(8))
                                : (index == 0
                                    ? const BorderRadius.vertical(
                                        top: Radius.circular(8))
                                    : BorderRadius.zero),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          if (!isLast)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.border,
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedCategory != null) {
      // 'ALL_CATEGORIES'가 반환되면 null을 전달하여 전체 출력
      final categoryToPrint =
          selectedCategory == 'ALL_CATEGORIES' ? null : selectedCategory;
      await _translateAndPrint(selectedLang, selectedCategory: categoryToPrint);
    }
  }

  Future<void> _translateAndPrint(String targetLang,
      {String? selectedCategory}) async {
    // If Japanese is selected, use original text
    if (targetLang == 'Japanese') {
      await _printMenu(
          titleTranslations: {},
          descTranslations: {},
          targetLang: targetLang,
          selectedCategory: selectedCategory);
      return;
    }

    // Prepare translation maps using STORED data only
    final titleTranslations = <String, String>{};
    final descTranslations = <String, String>{};

    // フィルタリングされたカテゴリーのみ対象にする
    final categoriesToProcess =
        selectedCategory != null ? [selectedCategory] : _categories;

    for (final cat in categoriesToProcess) {
      // Categories don't have stored translations in this model, so use original
      // Use original text for category (or implement category translation storage later)
      titleTranslations[cat] = cat;

      final menus = _categorizedMenu[cat] ?? [];
      for (final menu in menus) {
        // Title
        if (menu.titleTranslations.containsKey(targetLang)) {
          titleTranslations[menu.title] = menu.titleTranslations[targetLang]!;
        } else {
          // Fallback to original
          titleTranslations[menu.title] = menu.title;
        }

        // Description
        if (menu.description.isNotEmpty) {
          if (menu.descriptionTranslations.containsKey(targetLang)) {
            descTranslations[menu.description] =
                menu.descriptionTranslations[targetLang]!;
          } else {
            // Fallback to original
            descTranslations[menu.description] = menu.description;
          }
        }
      }
    }

    await _printMenu(
        titleTranslations: titleTranslations,
        descTranslations: descTranslations,
        targetLang: targetLang,
        selectedCategory: selectedCategory);
  }

  Future<void> _printMenu(
      {Map<String, String>? titleTranslations,
      Map<String, String>? descTranslations,
      String targetLang = 'Japanese',
      String? selectedCategory}) async {
    final doc = pw.Document();
    pw.Font font;
    pw.Font? fallbackFont;

    try {
      String fontUrl;
      switch (targetLang) {
        case 'ko':
          fontUrl =
              'https://fonts.gstatic.com/s/notosanskr/v39/PbyxFmXiEBPT4ITbgNA5Cgms3VYcOA-vvnIzzuoyeLQ.ttf';
          break;
        case 'zh':
          fontUrl =
              'https://fonts.gstatic.com/s/notosanssc/v40/k3kCo84MPvpLmixcA63oeAL7Iqp5IZJF9bmaG9_FnYw.ttf';
          break;
        case 'zh-TW':
          fontUrl =
              'https://fonts.gstatic.com/s/notosanstc/v39/-nFuOG829Oofr2wohFbTp9ifNAn722rq0MXz76Cy_Co.ttf';
          break;
        case 'ru':
        case 'pt':
          fontUrl =
              'https://fonts.gstatic.com/s/notosans/v42/o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjcz6L1SoM-jCpoiyD9A99d.ttf';
          break;
        case 'ar':
          fontUrl =
              'https://fonts.gstatic.com/s/notosansarabic/v33/nwpxtLGrOAZMl5nJ_wfgRg3DrWFZWsnVBJ_sS6tlqHHFlhQ5l3sQWIHPqzCfyGyvuw.ttf';
          break;
        case 'ja':
        case 'en':
        case 'fr':
        case 'es':
        case 'de':
        case 'it':
        default:
          fontUrl =
              'https://fonts.gstatic.com/s/notosansjp/v52/-F6jfjtqLzI2JPCgQBnw7HFyzSD-AsregP8VFBEj75s.ttf';
          break;
      }

      final fontResponse = await http.get(Uri.parse(fontUrl));
      font = pw.Font.ttf(fontResponse.bodyBytes.buffer.asByteData());

      // Load Japanese font as fallback if primary font is different
      // This ensures Japanese characters (e.g. from failed translations) are still rendered
      if (fontUrl !=
          'https://fonts.gstatic.com/s/notosansjp/v52/-F6jfjtqLzI2JPCgQBnw7HFyzSD-AsregP8VFBEj75s.ttf') {
        final fallbackResponse = await http.get(Uri.parse(
            'https://fonts.gstatic.com/s/notosansjp/v52/-F6jfjtqLzI2JPCgQBnw7HFyzSD-AsregP8VFBEj75s.ttf'));
        fallbackFont =
            pw.Font.ttf(fallbackResponse.bodyBytes.buffer.asByteData());
      }
    } catch (e) {
      debugPrint("Failed to load font: $e");
      font = pw.Font.courier();
    }

    // フィルタリングされたカテゴリーのみ対象にする
    final categoriesToProcess =
        selectedCategory != null ? [selectedCategory] : _categories;

    final allMenus = _categorizedMenu.values.expand((l) => l).toList();
    final imageFutures = <Future<void>>[];
    final Map<String, pw.ImageProvider> menuImages = {};

    for (final menu in allMenus) {
      if (menu.menuImageUrl.isNotEmpty) {
        imageFutures.add(() async {
          try {
            final image = await networkImage(menu.menuImageUrl);
            menuImages[menu.id] = image;
          } catch (e) {
            debugPrint('Failed to load image for ${menu.title}: $e');
          }
        }());
      }
    }

    await Future.wait(imageFutures).timeout(
      const Duration(seconds: 5),
      onTimeout: () => [],
    );

    String getTitleText(String original) {
      return titleTranslations?[original] ?? original;
    }

    String getDescText(String original) {
      return descTranslations?[original] ?? original;
    }

    pw.Widget buildTitleWidget(String fullText,
        {double fontSize = 14, bool isBold = false}) {
      final parts = fullText.split(' / ');
      if (parts.length > 1) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              parts[0],
              textDirection: targetLang == 'ar'
                  ? pw.TextDirection.rtl
                  : pw.TextDirection.ltr,
              style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
            pw.Text(
              parts.sublist(1).join(' / '),
              textDirection: pw.TextDirection.ltr, // Romaji is always LTR
              style: pw.TextStyle(
                fontSize: fontSize - 4,
                color: PdfColors.grey700,
                // fontStyle: pw.FontStyle.italic, // Optional
              ),
            ),
          ],
        );
      } else {
        return pw.Text(
          fullText,
          textDirection:
              targetLang == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        );
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: font,
          fontFallback: fallbackFont != null ? [fallbackFont] : [],
        ),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                      switch (targetLang) {
                        'ja' || 'Japanese' => 'メニュー',
                        'ko' => '메뉴',
                        'zh' => '菜单',
                        'zh-TW' => '菜單',
                        'ru' => 'Меню',
                        'es' => 'Menú',
                        'de' => 'Menü',
                        'it' => 'Menù',
                        'pt' => 'Menu',
                        'ar' => 'قائمة الطعام',
                        _ => 'Menu', // en fallback
                      },
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      'Date: ${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}',
                      style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.SizedBox(height: 20),
            ...categoriesToProcess.map((category) {
              final menus = _categorizedMenu[category]
                      ?.where((m) => m.menuStatus == 'available')
                      .toList() ??
                  [];
              if (menus.isEmpty) return pw.Container();

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 10, bottom: 10),
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom:
                              pw.BorderSide(width: 1, color: PdfColors.grey)),
                    ),
                    width: double.infinity,
                    child: buildTitleWidget(
                      getTitleText(category),
                      fontSize: 18,
                      isBold: true,
                    ),
                  ),
                  ...menus.map((menu) {
                    final imageProvider = menuImages[menu.id];

                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (imageProvider != null)
                            pw.Container(
                              width: 60,
                              height: 60,
                              margin: const pw.EdgeInsets.only(right: 12),
                              child:
                                  pw.Image(imageProvider, fit: pw.BoxFit.cover),
                            )
                          else if (menu.menuImageUrl.isNotEmpty)
                            pw.Container(
                              width: 60,
                              height: 60,
                              margin: const pw.EdgeInsets.only(right: 12),
                              color: PdfColors.grey200,
                              child: pw.Center(
                                  child: pw.Text('No Image',
                                      style: const pw.TextStyle(
                                          fontSize: 8, color: PdfColors.grey))),
                            )
                          else
                            pw.Container(width: 72),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Expanded(
                                      child: buildTitleWidget(
                                        getTitleText(menu.title),
                                        fontSize: 14,
                                        isBold: true,
                                      ),
                                    ),
                                    pw.Text(
                                      '¥${menu.price.toInt()}',
                                      style: pw.TextStyle(
                                        fontSize: 14,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                pw.SizedBox(height: 4),
                                if (menu.description.isNotEmpty)
                                  pw.Text(
                                    getDescText(menu.description),
                                    textDirection: targetLang == 'ar'
                                        ? pw.TextDirection.rtl
                                        : pw.TextDirection.ltr,
                                    style: const pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  pw.SizedBox(height: 10),
                ],
              );
            }).toList(),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'menu_list_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync =
        ref.watch(menuItemsNotifierProvider(storeId: widget.storeId));
    final saveStatus = ref.watch(menuSaveStatusProvider);

    // カテゴリー数変化時のTabController再生成 + ロードエラーの1回だけのToast表示。
    // 既存の _onViewModelUpdated(addListener) と同じ役割
    ref.listen(menuItemsNotifierProvider(storeId: widget.storeId),
        (previous, next) {
      final categories = next.valueOrNull?.categories ?? const <String>[];
      if (categories.length != _tabController.length) {
        setState(() {
          // 現在 index を維持する
          final currentIndex = _tabController.index.clamp(
              0, categories.isNotEmpty ? categories.length - 1 : 0);

          _tabController.dispose();
          _tabController = TabController(
              length: categories.length, vsync: this, initialIndex: currentIndex);
          _addTabListener();
        });
      }

      if (next.hasError) {
        ToastWidget.show(context, _describeError(next.error!),
            type: ToastType.error);
      }
    });

    final categories = menuAsync.valueOrNull?.categories ?? const <String>[];
    final categorizedMenu = menuAsync.valueOrNull?.categorizedMenu ?? const {};
    // 初回ロード中(=まだ一度もデータを取得できていない間)のみローディング表示
    final isLoading = menuAsync.isLoading && !menuAsync.hasValue;

    return LayoutBuilder(
      builder: (context, constraints) {
        // mobile layout基準点
        const double mobileBreakpoint = 700;
        final bool isMobile = constraints.maxWidth < mobileBreakpoint;

        // mobile layout
        if (isMobile) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              title: const Text(
                'メニュー管理',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              actions: [
                _SaveStatusIndicator(status: saveStatus),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.print, color: AppColors.textPrimary),
                  tooltip: 'メニュー出力',
                  onPressed: _showLanguageSelectionDialog,
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        bottom: 150,
                        child: MenuListPanel(
                          tabController: _tabController,
                          categories: categories,
                          categorizedMenu: categorizedMenu,
                          onEditCategory: _showEditCategoryDialog,
                          onEditMenu: _showEditMenuDialog,
                        ),
                      ),

                      // 下段ボタンパネル
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ActionButtonsPanelMobile(
                          isCategoryEmpty: categories.isEmpty,
                          onAddCategory: _showAddCategoryDialog,
                          onAddMenu: _showAddMenuDialog,
                          // onSaveChanges: _saveChanges,
                          onResetAll: _showDeleteAllMenusDialog,
                        ),
                      ),

                      // ローディング表示
                      if (isLoading) const LoadingIndicator(),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // desktop layout
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              title: const Text(
                'メニュー管理',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              actions: [
                _SaveStatusIndicator(status: saveStatus),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.print, color: AppColors.textPrimary),
                  tooltip: 'メニュー出力',
                  onPressed: _showLanguageSelectionDialog,
                ),
                const SizedBox(width: 24),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: MenuListPanel(
                              tabController: _tabController,
                              categories: categories,
                              categorizedMenu: categorizedMenu,
                              onEditCategory: _showEditCategoryDialog,
                              onEditMenu: _showEditMenuDialog,
                            ),
                          ),
                          const VerticalDivider(
                              width: 0.5, color: AppColors.border),
                          Expanded(
                            flex: 1,
                            child: ActionButtonsPanel(
                              isCategoryEmpty: categories.isEmpty,
                              onAddCategory: _showAddCategoryDialog,
                              onAddMenu: _showAddMenuDialog,
                              // onSaveChanges: _saveChanges,
                              onResetAll: _showDeleteAllMenusDialog,
                            ),
                          ),
                        ],
                      ),
                      if (isLoading) const LoadingIndicator(),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

class _SaveStatusIndicator extends StatelessWidget {
  final SaveStatus status;

  const _SaveStatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SaveStatus.saving:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentPrimary,
                ),
              ),
              SizedBox(width: 8),
              Text('保存中...', style: TextStyle(fontSize: 12)),
            ],
          ),
        );
      case SaveStatus.error:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('保存失敗', style: TextStyle(fontSize: 12, color: Colors.red)),
            ],
          ),
        );
      case SaveStatus.saved:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Text('保存済み', style: TextStyle(fontSize: 12, color: Colors.green)),
            ],
          ),
        );
    }
  }
}
