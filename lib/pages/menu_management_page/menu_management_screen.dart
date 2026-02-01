import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/pages/menu_management_page/widgets/panels/action_button_panel_mobile.dart';
import '../../models/menu_list.dart';
import '../../services/menu_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/common_dialogs/confirmation_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';
import '../../widgets/common_widgets/loading_indicator.dart';
import 'menu_management_screen_viewmodel.dart';
import 'widgets/dialogs/category_form_dialog.dart';
import 'widgets/dialogs/menu_form_dialog.dart';
import '../../widgets/common_dialogs/base_dialog.dart';
import 'widgets/panels/action_buttons_panel.dart';
import 'widgets/panels/menu_list_panel.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class MenuManagementScreen extends StatelessWidget {
  final String storeId;
  const MenuManagementScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MenuManagementScreenViewModel(
          storeId: storeId, menuService: MenuService()),
      child: const _MenuManagementView(),
    );
  }
}

class _MenuManagementView extends StatefulWidget {
  const _MenuManagementView();

  @override
  State<_MenuManagementView> createState() => _MenuManagementViewState();
}

class _MenuManagementViewState extends State<_MenuManagementView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  late final MenuManagementScreenViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // context が安全な initState で ViewModel の参照を先に取得
    _viewModel = context.read<MenuManagementScreenViewModel>();

    _tabController =
        TabController(length: _viewModel.categories.length, vsync: this);

    _addTabListener();

    // 保存された参照を使用し、リスナー追加
    _viewModel.addListener(_onViewModelUpdated);

    // 初期エラーメッセージ処理のためPost-frameコールバックを使用
    if (_viewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ToastWidget.show(context, _viewModel.errorMessage!,
              type: ToastType.error);
          _viewModel.clearErrorMessage();
        }
      });
    }
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

  void _onViewModelUpdated() {
    // ViewModel のカテゴリーリストの長さが TabController の長さと異なる場合 (カテゴリー 追加/削除 時)
    // TabController を再生成する
    if (_viewModel.categories.length != _tabController.length) {
      if (mounted) {
        setState(() {
          // 現在 index を維持する
          final currentIndex = _tabController.index.clamp(
              0,
              _viewModel.categories.isNotEmpty
                  ? _viewModel.categories.length - 1
                  : 0);

          // 以前コントローラーを廃棄
          _tabController.dispose();

          // 新しい長さでコントローラー再生成
          _tabController = TabController(
              length: _viewModel.categories.length,
              vsync: this,
              initialIndex: currentIndex);

          // 再生成したコントローラーにリスナーを付け直す
          _addTabListener();
        });
      }
    }

    if (_viewModel.errorMessage != null && mounted) {
      ToastWidget.show(context, _viewModel.errorMessage!,
          type: ToastType.error);
      _viewModel.clearErrorMessage();
    }
  }

  @override
  void dispose() {
    // context.read の代わりに保存しておいた _viewModel 変数を安全に使用
    _viewModel.removeListener(_onViewModelUpdated);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddCategoryDialog() async {
    final newCategory = await showDialog<String>(
      context: context,
      builder: (_) =>
          CategoryFormDialog(existingCategories: _viewModel.categories),
    );
    if (newCategory != null) {
      // context.read の代わりに保存しておいた _viewModel 変数を安全に使用
      _viewModel.addCategory(newCategory);
      _tabController.animateTo(_viewModel.categories.length - 1);
    }
  }

  Future<void> _showEditCategoryDialog(int index) async {
    final oldCategory = _viewModel.categories[index];
    final newCategory = await showDialog<String>(
      context: context,
      builder: (_) => CategoryFormDialog(
          initialValue: oldCategory, existingCategories: _viewModel.categories),
    );
    if (newCategory != null && newCategory != oldCategory) {
      _viewModel.editCategory(oldCategory, newCategory);
    }
  }

  Future<void> _showDeleteCategoryDialog(int index) async {
    final confirmed = await showConfirmationDialog(
        context: context,
        title: 'カテゴリー削除',
        content: 'このカテゴリーと含まれる全てのメニューを削除しますか？');
    if (confirmed == true) {
      _viewModel.deleteCategory(index);
      ToastWidget.show(context, 'カテゴリーが削除されました', type: ToastType.success);
    }
  }

  Future<void> _showAddMenuDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => MenuFormDialog(
          storeId: _viewModel.storeId,
          category: _viewModel.categories[_tabController.index]),
    );

    if (result != null) {
      final newMenu = result['menu'] as MenuListItem;
      final imageBytes = result['imageFile'] as Uint8List?;

      // メニュー保存
      final savedMenu = await _viewModel.addMenu(newMenu);

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

        await _viewModel.updateMenuWithImage(savedMenu, imageFile);
      }

      ToastWidget.show(context, 'メニューが追加されました', type: ToastType.success);
    }
  }

  Future<void> _showEditMenuDialog(int categoryIndex, int menuIndex) async {
    final category = _viewModel.categories[categoryIndex];
    final menuItem = _viewModel.categorizedMenu[category]![menuIndex];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => MenuFormDialog(
          menuItem: menuItem, storeId: _viewModel.storeId, category: category),
    );

    if (result != null) {
      final updatedMenu = result['menu'] as MenuListItem;
      final imageBytes = result['imageFile'] as Uint8List?;
      final imageRemoved = result['imageRemoved'] as bool? ?? false;

      if (imageBytes != null) {
        // 新しいイメージ選択 → アップロード
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageFile = await File(path).writeAsBytes(imageBytes);
        await _viewModel.updateMenuWithImage(updatedMenu, imageFile);
      } else if (imageRemoved) {
        // イメージ削除　→ 空の文字列で更新
        final menuWithoutImage = updatedMenu.copyWith(menuImageUrl: '');
        _viewModel.editMenu(menuWithoutImage);
        ToastWidget.show(context, '画像が削除されました', type: ToastType.success);
      } else {
        // テキスト情報のみ更新
        _viewModel.editMenu(updatedMenu);
      }
    }
  }

  Future<void> _showDeleteMenuDialog(int categoryIndex, int menuIndex) async {
    final confirmed = await showConfirmationDialog(
        context: context, title: 'メニュー削除', content: '本当にこのメニューを削除しますか？');
    if (confirmed == true) {
      final category = _viewModel.categories[categoryIndex];
      _viewModel.deleteMenu(category, menuIndex);
      ToastWidget.show(context, 'メニューが削除されました', type: ToastType.success);
    }
  }

  Future<void> _showDeleteAllMenusDialog() async {
    final confirmed = await showConfirmationDialog(
        context: context,
        title: 'メニュー初期化',
        content: '全てのメニューを削除状態にしますか？\nこの操作は「保存」を押すと確定されます。');
    if (confirmed == true) {
      _viewModel.deleteAllMenus();
      ToastWidget.show(context, '全てのメニューが削除状態になりました', type: ToastType.info);
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
                      'English': '英語',
                      'Korean': '韓国語',
                      'Chinese': '中国語',
                      'Spanish': 'スペイン語',
                      'French': 'フランス語',
                      'German': 'ドイツ語',
                      'Italian': 'イタリア語',
                      'Arabic': 'アラビア語',
                    }.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final e = entry.value;
                      // Dynamic check for last item
                      final isLast = index == 7; // Total 8 items (0-7)

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
      _translateAndPrint(selectedLang);
    }
  }

  Future<void> _translateAndPrint(String targetLang) async {
    // If Japanese is selected, skip translation and print directly
    if (targetLang == 'Japanese') {
      await _printMenu(
          titleTranslations: {}, descTranslations: {}, targetLang: targetLang);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: LoadingIndicator()),
    );

    try {
      final titleTranslations = <String, String>{};
      final descTranslations = <String, String>{};
      final titleAndCategories = <String>{};
      final descriptions = <String>{};

      for (final cat in _viewModel.categories) {
        titleAndCategories.add(cat);
        final menus = _viewModel.categorizedMenu[cat] ?? [];
        for (final menu in menus) {
          titleAndCategories.add(menu.title);
          if (menu.description.isNotEmpty) {
            descriptions.add(menu.description);
          }
        }
      }

      // Prepare inputs
      final titleMap = <String, String>{};
      final titleList = titleAndCategories.toList();
      for (int i = 0; i < titleList.length; i++) {
        titleMap['t_$i'] = titleList[i];
      }

      final descMap = <String, String>{};
      final descList = descriptions.toList();
      for (int i = 0; i < descList.length; i++) {
        descMap['d_$i'] = descList[i];
      }

      // Merge maps for single optimization call
      final allMap = <String, String>{...titleMap, ...descMap};

      final result = await TranslationService().translateBatch(
        allMap,
        targetLang: targetLang,
        smartMenuMode: true, // Use smart mode for selective Romaji
      );

      // Process Title Results
      for (int i = 0; i < titleList.length; i++) {
        final key = 't_$i';
        if (result.containsKey(key)) {
          titleTranslations[titleList[i]] = result[key]!;
        } else {
          titleTranslations[titleList[i]] = titleList[i];
        }
      }

      // Process Description Results
      for (int i = 0; i < descList.length; i++) {
        final key = 'd_$i';
        if (result.containsKey(key)) {
          descTranslations[descList[i]] = result[key]!;
        } else {
          descTranslations[descList[i]] = descList[i];
        }
      }

      if (mounted) {
        Navigator.pop(context);
        _printMenu(
            titleTranslations: titleTranslations,
            descTranslations: descTranslations,
            targetLang: targetLang);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ToastWidget.show(context, '翻訳に失敗しました: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _printMenu(
      {Map<String, String>? titleTranslations,
      Map<String, String>? descTranslations,
      String targetLang = 'Japanese'}) async {
    final doc = pw.Document();
    pw.Font font;
    pw.Font? fallbackFont;

    try {
      String fontUrl;
      switch (targetLang) {
        case 'Korean':
          fontUrl =
              'https://fonts.gstatic.com/s/notosanskr/v39/PbyxFmXiEBPT4ITbgNA5Cgms3VYcOA-vvnIzzuoyeLQ.ttf';
          break;
        case 'Chinese':
          fontUrl =
              'https://fonts.gstatic.com/s/notosanssc/v40/k3kCo84MPvpLmixcA63oeAL7Iqp5IZJF9bmaG9_FnYw.ttf';
          break;
        case 'Arabic':
          fontUrl =
              'https://fonts.gstatic.com/s/notosansarabic/v33/nwpxtLGrOAZMl5nJ_wfgRg3DrWFZWsnVBJ_sS6tlqHHFlhQ5l3sQWIHPqzCfyGyvuw.ttf';
          break;
        case 'Japanese':
        case 'English':
        case 'French':
        case 'Spanish':
        case 'German':
        case 'Italian':
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

    final allMenus =
        _viewModel.categorizedMenu.values.expand((l) => l).toList();
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

    pw.Widget _buildTitleWidget(String fullText,
        {double fontSize = 14, bool isBold = false}) {
      final parts = fullText.split(' / ');
      if (parts.length > 1) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              parts[0],
              textDirection: targetLang == 'Arabic'
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
          textDirection: targetLang == 'Arabic'
              ? pw.TextDirection.rtl
              : pw.TextDirection.ltr,
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
                        'Japanese' => 'メニュー',
                        'Korean' => '메뉴',
                        'Chinese' => '菜单',
                        'Spanish' => 'Menú',
                        'German' => 'Menü',
                        'Italian' => 'Menù',
                        'Arabic' => 'قائمة الطعام',
                        _ => 'Menu', // English, French fallback
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
            ..._viewModel.categories.map((category) {
              final menus = _viewModel.categorizedMenu[category]
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
                    child: _buildTitleWidget(
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
                                      child: _buildTitleWidget(
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
                                    textDirection: targetLang == 'Arabic'
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
    final vm = context.watch<MenuManagementScreenViewModel>();

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
                _SaveStatusIndicator(status: vm.saveStatus),
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
                          categories: vm.categories,
                          categorizedMenu: vm.categorizedMenu,
                          onEditCategory: _showEditCategoryDialog,
                          onDeleteCategory: _showDeleteCategoryDialog,
                          onEditMenu: _showEditMenuDialog,
                          onDeleteMenu: _showDeleteMenuDialog,
                        ),
                      ),

                      // 下段ボタンパネル
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ActionButtonsPanelMobile(
                          isCategoryEmpty: vm.categories.isEmpty,
                          onAddCategory: _showAddCategoryDialog,
                          onAddMenu: _showAddMenuDialog,
                          // onSaveChanges: _saveChanges,
                          onResetAll: _showDeleteAllMenusDialog,
                        ),
                      ),

                      // ローディング表示
                      if (vm.isLoading) const LoadingIndicator(),
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
                _SaveStatusIndicator(status: vm.saveStatus),
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
                              categories: vm.categories,
                              categorizedMenu: vm.categorizedMenu,
                              onEditCategory: _showEditCategoryDialog,
                              onDeleteCategory: _showDeleteCategoryDialog,
                              onEditMenu: _showEditMenuDialog,
                              onDeleteMenu: _showDeleteMenuDialog,
                            ),
                          ),
                          const VerticalDivider(
                              width: 0.5, color: AppColors.border),
                          Expanded(
                            flex: 1,
                            child: ActionButtonsPanel(
                              isCategoryEmpty: vm.categories.isEmpty,
                              onAddCategory: _showAddCategoryDialog,
                              onAddMenu: _showAddMenuDialog,
                              // onSaveChanges: _saveChanges,
                              onResetAll: _showDeleteAllMenusDialog,
                            ),
                          ),
                        ],
                      ),
                      if (vm.isLoading) const LoadingIndicator(),
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
                child: CircularProgressIndicator(strokeWidth: 2),
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
