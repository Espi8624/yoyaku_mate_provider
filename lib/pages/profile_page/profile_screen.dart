import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets/custom_snack_bar.dart';
import 'profile_viewmodel.dart';
import './widgets/views/personal_profile_view.dart';
import './widgets/views/store_profile_view.dart';

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
  late final ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ProfileViewModel>();

    _viewModel.addListener(_onViewModelUpdated);

    _setupTabController();
  }

  void _onViewModelUpdated() {
    if (!mounted) return;

    if (_viewModel.errorMessage != null) {
      CustomSnackBar.show(context,
          message: _viewModel.errorMessage!, status: SnackBarStatus.error);
    }

    // データが変更される時、TabController 設定を行う
    _setupTabController();
  }

  // TabController を設定
  void _setupTabController() {
    // ViewModel へ userProfile データがない場合何もしない
    if (_viewModel.userProfile == null) return;

    final newLength = _viewModel.userProfile!.role == "manager" ? 2 : 1;

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
    final vm = context.watch<ProfileViewModel>();
    final bool isManager = vm.userProfile?.role == 'manager';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.all(24),
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
  Widget _buildContent(ProfileViewModel vm, bool isManager) {
    if (vm.userProfile == null) {
      return const Center(child: Text("ユーザー情報が見つかりません。"));
    }

    // Success
    return Column(
      children: [
        // 管理者の場合、TabBar を表示
        if (isManager) ...[
          Center(child: _buildTabBar()),
          const SizedBox(height: 24),
        ],

        // TabBarView または、個人 Profile View を表示
        Expanded(
          child: isManager
              ? TabBarView(
                  controller: _tabController!,
                  children: [
                    PersonalProfileView(userProfile: vm.userProfile!),

                    // store profile が null の場合を備えた防御コード
                    if (vm.storeProfile != null)
                      StoreProfileView(storeProfile: vm.storeProfile!)
                    else
                      const Center(child: Text("店舗情報がありません。")),
                  ],
                )
              : PersonalProfileView(userProfile: vm.userProfile!),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 34,
      width: 190,
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
        tabs: const [Tab(text: '個人'), Tab(text: '店舗')],
      ),
    );
  }
}
