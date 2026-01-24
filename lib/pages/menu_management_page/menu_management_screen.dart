import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/pages/menu_management_page/widgets/panels/action_button_panel_mobile.dart';
import '../../models/menu_list.dart';
import '../../services/menu_service.dart';
import '../../widgets/common_dialogs/confirmation_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';
import '../../widgets/common_widgets/loading_indicator.dart';
import 'menu_management_screen_viewmodel.dart';
import 'widgets/dialogs/category_form_dialog.dart';
import 'widgets/dialogs/menu_form_dialog.dart';
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
