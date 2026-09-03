import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../constants/app_colors.dart';
import 'widgets/staff_management_view.dart';
import 'widgets/shift_table_view.dart';

// Riverpodへの移行後は ChangeNotifierProvider によるViewModelのスコープ生成が不要になった
// (staffListProvider/staffActionsProvider は family の autoDispose によって
//  画面遷移時に自動的に破棄される)
//
// ページ1: スタッフ管理 (承認/権限/勤務可能時間)、ページ2: シフト表
// profile_screen.dart の設定画面(一般/店舗)と同じピル型TabBarを踏襲し、
// タブをタップすると即座に切り替わる。スワイプでの切替も TabBarView によりそのまま可能
class StaffManagementScreen extends HookWidget {
  final String storeId;

  const StaffManagementScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "スタッフ管理",
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

          final content = _buildContent(tabController);
          return isMobile ? SafeArea(child: content) : content;
        },
      ),
    );
  }

  Widget _buildContent(TabController tabController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _buildTabBar(tabController)),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              StaffManagementView(storeId: storeId),
              ShiftTableView(storeId: storeId),
            ],
          ),
        ),
      ],
    );
  }

  // profile_screen.dart の _buildTabBar と同一デザイン (ピル型セグメントコントロール)
  Widget _buildTabBar(TabController tabController) {
    const width = 220.0;

    return Container(
      height: 34,
      width: width,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                color: AppColors.accentPrimary.withValues(alpha: 0.25),
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
          Tab(text: 'スタッフ管理'),
          Tab(text: 'シフト表'),
        ],
      ),
    );
  }
}
