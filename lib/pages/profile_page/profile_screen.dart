import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';
import 'profile_screen_viewmodel.dart';
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
      ToastWidget.show(context, _viewModel.errorMessage!,
          type: ToastType.error);
    }
    // 成功表示
    else if (_viewModel.successMessage != null) {
      ToastWidget.show(context, _viewModel.successMessage!,
          type: ToastType.success);
      _viewModel.clearSuccessMessage();
    }

    // データが変更される時、TabController 設定を行う
    _setupTabController();
  }

  // TabController を設定
  void _setupTabController() {
    // ViewModel へ userProfile データがない場合何もしない
    if (_viewModel.userProfile == null) return;

    // 常に2つ（個人、店舗）
    const newLength = 2;

    // コントローラーが生成され、長さが同じ時、何もしない
    if (_tabController != null && _tabController!.length == newLength) return;

    // 状態を変更しないといけないため、setState ないで、コントローラーを生成/再生成する
    setState(() {
      // 以前コントローラーが存在していた場合、dispose
      _tabController?.dispose();
      // ViewModelに保存されたインデックスで初期化
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: _viewModel.profileTabIndex,
      );

      // タブ変更時にViewModelを更新
      _tabController?.addListener(() {
        if (_tabController != null && !_tabController!.indexIsChanging) {
          _viewModel.setProfileTabIndex(_tabController!.index);
        }
      });
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "設定",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double mobileBreakpoint = 700;
          final bool isMobile = constraints.maxWidth < mobileBreakpoint;

          if (isMobile) {
            return SafeArea(
              child: _buildColumn(vm: vm, isManager: isManager),
            );
          } else {
            return _buildColumn(vm: vm, isManager: isManager);
          }
        },
      ),
    );
  }

  Widget _buildColumn(
      {required ProfileScreenViewModel vm, required bool isManager}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header

        // Contents
        Expanded(
          // _tabController が生成されるまではローディングインディケーターを表示
          // 競争状態防止
          child: _tabController == null
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(vm, isManager),
        ),
      ],
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
        Center(child: _buildTabBar()),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    // タブの数に応じて幅を調整
    const width = 190.0;

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
        tabs: const [
          Tab(text: '一般'),
          Tab(text: '店舗'),
        ],
      ),
    );
  }
}
