import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/pages/menu_management_page/widgets/panels/action_button_panel_mobile.dart';
import '../../models/menu_list.dart';
import '../../services/api_exception.dart';
import '../../services/menu_service.dart';
import '../../widgets/common_dialogs/confirmation_dialog.dart';
import '../../widgets/common_widgets/custom_snack_bar.dart';
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
          CustomSnackBar.show(context,
              message: _viewModel.errorMessage!, status: SnackBarStatus.error);
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
      CustomSnackBar.show(context,
          message: _viewModel.errorMessage!, status: SnackBarStatus.error);
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
      CustomSnackBar.show(context,
          message: 'カテゴリーが削除されました', status: SnackBarStatus.success);
    }
  }

  Future<void> _showAddMenuDialog() async {
    final newMenu = await showDialog<MenuListItem>(
      context: context,
      builder: (_) => MenuFormDialog(
          storeId: _viewModel.storeId,
          category: _viewModel.categories[_tabController.index]),
    );
    if (newMenu != null) {
      _viewModel.addMenu(newMenu);
    }
  }

  Future<void> _showEditMenuDialog(int categoryIndex, int menuIndex) async {
    final category = _viewModel.categories[categoryIndex];
    final menuItem = _viewModel.categorizedMenu[category]![menuIndex];
    final updatedMenu = await showDialog<MenuListItem>(
      context: context,
      builder: (_) => MenuFormDialog(
          menuItem: menuItem, storeId: _viewModel.storeId, category: category),
    );
    if (updatedMenu != null) {
      _viewModel.editMenu(updatedMenu);
    }
  }

  Future<void> _showDeleteMenuDialog(int categoryIndex, int menuIndex) async {
    final confirmed = await showConfirmationDialog(
        context: context, title: 'メニュー削除', content: '本当にこのメニューを削除しますか？');
    if (confirmed == true) {
      final category = _viewModel.categories[categoryIndex];
      _viewModel.deleteMenu(category, menuIndex);
      CustomSnackBar.show(context,
          message: 'メニューが削除されました', status: SnackBarStatus.success);
    }
  }

  Future<void> _showDeleteAllMenusDialog() async {
    final confirmed = await showConfirmationDialog(
        context: context,
        title: 'メニュー初期化',
        content: '全てのメニューを削除状態にしますか？\nこの操作は「保存」を押すと確定されます。');
    if (confirmed == true) {
      _viewModel.deleteAllMenus();
      CustomSnackBar.show(context,
          message: '全てのメニューが削除状態になりました', status: SnackBarStatus.info);
    }
  }

  Future<void> _saveChanges() async {
    if (!_viewModel.hasChanges()) {
      CustomSnackBar.show(context,
          message: '変更がありません', status: SnackBarStatus.info);
      return;
    }
    try {
      await _viewModel.saveChanges();
      CustomSnackBar.show(context,
          message: 'メニューが保存されました', status: SnackBarStatus.success);
    } on ApiException catch (e) {
      CustomSnackBar.show(context,
          message: '保存に失敗しました: ${e.message}', status: SnackBarStatus.error);
    }
  }

  @override
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
            // appBar: AppBar(
            //   title: const Text('メニュー管理',
            //       style: TextStyle(fontWeight: FontWeight.bold)),
            //   backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            //   elevation: 0,
            // ),
            body: Stack(
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
                    onSaveChanges: _saveChanges,
                    onResetAll: _showDeleteAllMenusDialog,
                  ),
                ),

                // ローディング表示
                if (vm.isLoading) const LoadingIndicator(),
              ],
            ),
          );
        } else {
          // desktop layout
          return Scaffold(
            body: Stack(
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
                    const VerticalDivider(width: 0.5, color: AppColors.border),
                    Expanded(
                      flex: 1,
                      child: ActionButtonsPanel(
                        isCategoryEmpty: vm.categories.isEmpty,
                        onAddCategory: _showAddCategoryDialog,
                        onAddMenu: _showAddMenuDialog,
                        onSaveChanges: _saveChanges,
                        onResetAll: _showDeleteAllMenusDialog,
                      ),
                    ),
                  ],
                ),
                if (vm.isLoading) const LoadingIndicator(),
              ],
            ),
          );
        }
      },
    );
  }
}
