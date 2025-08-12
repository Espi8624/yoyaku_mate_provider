import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'tabs/operation_settings_tab.dart';
import 'tabs/waiting_settings_tab.dart';
import 'setting_screen_viewmodel.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets/custom_snack_bar.dart';

// 設定ページの最上位ウィジェット
// Providerを通じてViewModelを注入
class SettingScreen extends StatelessWidget {
  final String storeId;
  const SettingScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingScreenViewModel(storeId: storeId),
      child: const _SettingScreenView(),
    );
  }
}

// 実際 UI を描く View ウィジェット
// ViewModel の状態を購読
class _SettingScreenView extends StatefulWidget {
  const _SettingScreenView();

  @override
  State<_SettingScreenView> createState() => _SettingScreenViewState();
}

class _SettingScreenViewState extends State<_SettingScreenView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final SettingScreenViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel = context.read<SettingScreenViewModel>();
    _viewModel.addListener(_handleChanges);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleChanges);
    _tabController.dispose();
    super.dispose();
  }

  void _handleChanges() {
    if (_viewModel.errorMessage != null && mounted) {
      CustomSnackBar.show(context,
          message: _viewModel.errorMessage!, status: SnackBarStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingScreenViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("設定",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            _buildTabBar(),
            const SizedBox(height: 24),
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : viewModel.storeSettings == null
                      ? Center(
                          child: Text('設定情報を表示できません。',
                              style: TextStyle(color: AppColors.textSecondary)))
                      : _buildTabBarView(viewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.textPrimaryLight,
        unselectedLabelColor: AppColors.textPrimary,
        isScrollable: false,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding:
            const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        indicator: ShapeDecoration(
          color: AppColors.accentPrimary,
          shape: const StadiumBorder(),
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '運営設定'),
          Tab(text: '待機リスト設定'),
        ],
      ),
    );
  }

  Widget _buildTabBarView(SettingScreenViewModel viewModel) {
    return TabBarView(
      controller: _tabController,
      children: [
        OperationSettingsTab(
          storeSettings: viewModel.storeSettings!,
          onChanged: (updatedSettings) =>
              viewModel.updateSettings(updatedSettings),
        ),
        WaitingSettingsTab(
          storeSettings: viewModel.storeSettings!,
          onChanged: (updatedSettings) =>
              viewModel.updateSettings(updatedSettings),
        ),
      ],
    );
  }
}
