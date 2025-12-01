import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets/custom_snack_bar.dart';
import 'profile_screen_viewmodel.dart';
import './widgets/views/personal_profile_view.dart';
import './widgets/views/store_profile_view.dart';
import './widgets/views/staff_management_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileView();
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView>
    with TickerProviderStateMixin {
  TabController? _tabController;
  late final ProfileScreenViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ProfileScreenViewModel>();

    _viewModel.addListener(_onViewModelUpdated);

    _setupTabController();
  }

  void _onViewModelUpdated() {
    if (!mounted) return;

    // エラー表示
    if (_viewModel.errorMessage != null) {
      CustomSnackBar.show(context,
          message: _viewModel.errorMessage!, status: SnackBarStatus.error);
    }
    // 成功表示
    else if (_viewModel.successMessage != null) {
      CustomSnackBar.show(context,
          message: _viewModel.successMessage!, status: SnackBarStatus.success);
      _viewModel.clearSuccessMessage();
    }

    // データが変更される時、TabController 設定を行う
    _setupTabController();
  }

  // TabController を設定
  void _setupTabController() {
    // ViewModel へ userProfile データがない場合何もしない
    if (_viewModel.userProfile == null) return;

    final isManager = _viewModel.userProfile!.role == "manager";
    // マネージャーなら3つ（個人、店舗、スタッフ）、それ以外は2つ
    final newLength = isManager ? 3 : 2;

    // コントローラーが生成され、長さが同じ時、何もしない
    if (_tabController != null && _tabController!.length == newLength) return;

    // 状態を変更しないといけないため、setState ないで、コントローラーを生成/再生成する
    setState(() {
      // 以前コントローラーが存在していた場合、dispose
      _tabController?.dispose();
      _tabController = TabController(length: newLength, vsync: this);
    });
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdated);
    // nullable コントローラーを dispose
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // context.watch を使用し、ViewModel の状態変化を感知し、UI をビルドし直し
    final vm = context.watch<ProfileScreenViewModel>();
    final bool isManager = vm.userProfile?.role == 'manager';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 36),
              child: Text("プロフィール設定",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ),
            // Contents
            Expanded(
              // _tabController が生成されるまではローディングインディケーターを表示
              // 競争状態防止
              child: _tabController == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(vm, isManager),
            ),
          ],
        ),
      ),
    );
  }

  // ViewModel の状態によって適切なコンテンツ Widgets を返却するヘルパーメソッド
  Widget _buildContent(ProfileScreenViewModel vm, bool isManager) {
    if (vm.userProfile == null) {
      return const Center(child: Text("ユーザー情報が見つかりません。"));
    }

    return Column(
      children: [
        // 役割に関係なく、TabBar を表示
        Center(child: _buildTabBar(isManager)),
        const SizedBox(height: 24),

        // TabBarView を表示
        Expanded(
          child: TabBarView(
            controller: _tabController!,
            children: [
              PersonalProfileView(userProfile: vm.userProfile!),

              // store profile が null の場合を備えた防御コード
              if (vm.storeProfile != null)
                StoreProfileView(isReadOnly: !isManager)
              else
                const Center(child: Text("店舗情報がありません。")),

              // マネージャーの場合のみスタッフ管理画面を表示
              if (isManager && vm.storeProfile != null)
                StaffManagementView(storeId: vm.storeProfile!.id),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isManager) {
    // タブの数に応じて幅を調整
    final width = isManager ? 285.0 : 190.0;

    return Container(
      height: 34,
      width: width,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: AppColors.textPrimary,
          boxShadow: [
            BoxShadow(
                color: AppColors.accentPrimary.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[700],
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        tabs: [
          const Tab(text: '個人'),
          const Tab(text: '店舗'),
          if (isManager) const Tab(text: 'スタッフ'),
        ],
      ),
    );
  }
}
