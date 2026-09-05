import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'widgets/staff_management_view.dart';
import 'widgets/shift_table_screen.dart';

// Riverpodへの移行後は ChangeNotifierProvider によるViewModelのスコープ生成が不要になった
// (staffListProvider/staffActionsProvider は family の autoDispose によって
//  画面遷移時に自動的に破棄される)
//
// 스태프관리(승인/권한/근무가능시간) 화면. 시프트표는 탭이 아니라
// 타이틀 오른쪽 달력 아이콘 버튼으로 새 화면(ShiftTableScreen)을 열어 표시한다
// (탭 UI가 화면 상단 공간을 과도하게 차지해 제거함)
class StaffManagementScreen extends StatelessWidget {
  final String storeId;

  const StaffManagementScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            // 아이콘만으로는 용도가 모호할 수 있어 텍스트를 함께 표시하는 필(pill)형 버튼으로 구성
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('シフト表'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ShiftTableScreen(storeId: storeId),
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double mobileBreakpoint = 700;
          final bool isMobile = constraints.maxWidth < mobileBreakpoint;

          final content = StaffManagementView(storeId: storeId);
          return isMobile ? SafeArea(child: content) : content;
        },
      ),
    );
  }
}
