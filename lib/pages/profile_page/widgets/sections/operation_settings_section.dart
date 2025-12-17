import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/store_settings.dart';
import '../../../../widgets/common_widgets/custom_snack_bar.dart';
import '../../dialogs/business_hours_dialog.dart';
import '../../dialogs/holiday_dialog.dart';
import '../../profile_screen_viewmodel.dart';
import '../profile_section.dart';
import '../profile_setting_item.dart';

class OperationSettingsSection extends StatelessWidget {
  final bool isReadOnly;

  const OperationSettingsSection({
    super.key,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileScreenViewModel>();
    final storeSettings = vm.storeSettings;

    if (storeSettings == null) {
      if (vm.isLoading) {
        return const SizedBox(); // Loading handled by parent or overlay
      }
      return const SizedBox(); // Or error message
    }

    return ProfileSection(
      title: '運営設定',
      children: [
        ProfileSettingItem(
          title: '営業時間',
          subtitle: _buildBusinessHoursSummary(storeSettings.operatingHours),
          showTrailingIcon: !isReadOnly,
          onTap:
              isReadOnly ? null : () => _showBusinessHoursDialog(context, vm),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ProfileSettingItem(
          title: '休業日',
          subtitle: storeSettings.closedDays.summary,
          showTrailingIcon: !isReadOnly,
          onTap: isReadOnly ? null : () => _showHolidayDialog(context, vm),
        ),
      ],
    );
  }

  String _buildBusinessHoursSummary(Map<String, Map<String, String>> hours) {
    final weekdayHours =
        '${hours['monday']?['start'] ?? ''}-${hours['monday']?['end'] ?? ''}';
    return '平日: $weekdayHours';
  }

  Future<void> _showBusinessHoursDialog(
      BuildContext context, ProfileScreenViewModel vm) async {
    final storeSettings = vm.storeSettings;
    if (storeSettings == null) return;

    final result = await showDialog<Map<String, Map<String, String>>>(
      context: context,
      builder: (_) =>
          BusinessHoursDialog(initialHours: storeSettings.operatingHours),
    );

    if (result != null) {
      final updatedSettings = storeSettings.copyWith(operatingHours: result);
      await vm.updateStoreSettings(updatedSettings);

      if (context.mounted) {
        if (vm.errorMessage != null) {
          CustomSnackBar.show(context,
              message: vm.errorMessage!, status: SnackBarStatus.error);
        } else if (vm.successMessage != null) {
          CustomSnackBar.show(context,
              message: vm.successMessage!, status: SnackBarStatus.success);
          vm.clearSuccessMessage();
        }
      }
    }
  }

  Future<void> _showHolidayDialog(
      BuildContext context, ProfileScreenViewModel vm) async {
    final storeSettings = vm.storeSettings;
    if (storeSettings == null) return;

    final result = await showDialog<ClosedDays>(
      context: context,
      builder: (_) =>
          HolidayDialog(initialClosedDays: storeSettings.closedDays),
    );

    if (result != null) {
      final updatedSettings = storeSettings.copyWith(closedDays: result);
      await vm.updateStoreSettings(updatedSettings);

      if (context.mounted) {
        if (vm.errorMessage != null) {
          CustomSnackBar.show(context,
              message: vm.errorMessage!, status: SnackBarStatus.error);
        } else if (vm.successMessage != null) {
          CustomSnackBar.show(context,
              message: vm.successMessage!, status: SnackBarStatus.success);
          vm.clearSuccessMessage();
        }
      }
    }
  }
}
