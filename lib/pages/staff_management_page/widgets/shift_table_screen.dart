import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import 'shift_table_view.dart';

// 스태프관리 화면의 달력 버튼에서 이동하는 주간 시프트표 전체 화면
// StaffManagementScreen과 동일한 LayoutBuilder + SafeArea(모바일 breakpoint 700) 처리를 그대로 적용
class ShiftTableScreen extends StatelessWidget {
  final String storeId;

  const ShiftTableScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'シフト表',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double mobileBreakpoint = 700;
          final bool isMobile = constraints.maxWidth < mobileBreakpoint;

          final content = ShiftTableView(storeId: storeId);
          return isMobile ? SafeArea(child: content) : content;
        },
      ),
    );
  }
}
