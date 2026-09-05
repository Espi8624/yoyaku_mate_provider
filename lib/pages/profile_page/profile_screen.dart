import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../constants/app_colors.dart';
import 'package:yoyaku_mate_provider/models/store_profile.dart';
import 'package:yoyaku_mate_provider/models/user_profile.dart';
import 'package:yoyaku_mate_provider/providers/session_providers.dart';
import './widgets/views/personal_profile_view.dart';
import './widgets/views/store_profile_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileView();
  }
}

// タブ切替(個人/店舗)はページローカルなEphemeral Stateのため useTabController で保持する
// (以前はProfileScreenViewModelのprofileTabIndexとしてグローバルに保持していたが、
//  このページ以外から参照されていなかったためローカル化した)
class _ProfileView extends HookConsumerWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 2);

    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final bool isManager = userProfile?.role == 'manager';
    final storeProfile = ref.watch(selectedStoreProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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

          final content = _buildContent(
            tabController: tabController,
            userProfile: userProfile,
            storeProfile: storeProfile,
            isManager: isManager,
          );

          if (isMobile) {
            return SafeArea(child: content);
          } else {
            return content;
          }
        },
      ),
    );
  }

  Widget _buildContent({
    required TabController tabController,
    required UserProfile? userProfile,
    required StoreProfile? storeProfile,
    required bool isManager,
  }) {
    if (userProfile == null) {
      return const Center(child: Text("ユーザー情報が見つかりません。"));
    }

    return Column(
      children: [
        Center(child: _buildTabBar(tabController)),
        const SizedBox(height: 24),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              PersonalProfileView(userProfile: userProfile),

              // store profile が null の場合を備えた防御コード
              if (storeProfile != null)
                StoreProfileView(isReadOnly: !isManager)
              else
                const Center(child: Text("店舗情報がありません。")),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(TabController tabController) {
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
        controller: tabController,
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
