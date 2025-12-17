import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../services/profile_service.dart';
import 'staff_management_viewmodel.dart';
import 'widgets/staff_management_view.dart';

class StaffManagementScreen extends StatelessWidget {
  final String storeId;

  const StaffManagementScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StaffManagementViewModel(
        profileService: context.read<ProviderProfileService>(),
      ),
      child: Scaffold(
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
      ),
    );
  }

  Widget _buildColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Text(
            "スタッフ管理",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: StaffManagementView(storeId: storeId),
        ),
      ],
    );
  }
}
