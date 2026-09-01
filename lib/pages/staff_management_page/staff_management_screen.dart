import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'widgets/staff_management_view.dart';

// Riverpodへの移行後は ChangeNotifierProvider によるViewModelのスコープ生成が不要になった
// (staffListProvider/staffActionsProvider は family の autoDispose によって
//  画面遷移時に自動的に破棄される)
class StaffManagementScreen extends StatelessWidget {
  final String storeId;

  const StaffManagementScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
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

          if (isMobile) {
            return SafeArea(
              child: _buildColumn(),
            );
          } else {
            return _buildColumn();
          }
        },
      ),
    );
  }

  Widget _buildColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: StaffManagementView(storeId: storeId),
        ),
      ],
    );
  }
}
