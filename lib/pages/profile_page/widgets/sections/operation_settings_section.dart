import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/store_settings.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';
import '../../dialogs/business_hours_dialog.dart';
import '../../dialogs/holiday_dialog.dart';
import '../../dialogs/number_input_dialog.dart';
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
          title: 'チームあたりの予想待機時間',
          subtitle: '${storeSettings.waitingPolicy.estimatedWaitTime ?? 10}分',
          showTrailingIcon: !isReadOnly,
          onTap: isReadOnly ? null : () => _showEditWaitTimeDialog(context, vm),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ProfileSettingItem(
          title: '営業時間',
          subtitle: storeSettings.is24Hours
              ? '24時間営業 (リセット: ${storeSettings.resetTime})'
              : _buildBusinessHoursSummary(storeSettings.operatingHours),
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

  Future<void> _showEditWaitTimeDialog(
      BuildContext context, ProfileScreenViewModel vm) async {
    final storeSettings = vm.storeSettings;
    if (storeSettings == null) return;

    final result = await showDialog<int>(
      context: context,
      builder: (_) => NumberInputDialog(
          title: '予想待機時間設定',
          labelText: '分 (1チームあたり)',
          initialValue: storeSettings.waitingPolicy.estimatedWaitTime ?? 10),
    );

    if (result != null) {
      final updatedPolicy =
          storeSettings.waitingPolicy.copyWith(estimatedWaitTime: result);
      final updatedSettings =
          storeSettings.copyWith(waitingPolicy: updatedPolicy);
      await vm.updateStoreSettings(updatedSettings);

      if (context.mounted) {
        if (vm.errorMessage != null) {
          ToastWidget.show(context, vm.errorMessage!, type: ToastType.error);
        } else if (vm.successMessage != null) {
          ToastWidget.show(context, '予想待機時間が${result}分に設定されました。',
              type: ToastType.success);
          vm.clearSuccessMessage();
        }
      }
    }
  }

  Future<void> _showBusinessHoursDialog(
      BuildContext context, ProfileScreenViewModel vm) async {
    final storeSettings = vm.storeSettings;
    if (storeSettings == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => BusinessHoursDialog(
        initialHours: storeSettings.operatingHours,
        initialIs24Hours: storeSettings.is24Hours,
        initialResetTime: storeSettings.resetTime,
      ),
    );

    if (result != null) {
      final updatedSettings = storeSettings.copyWith(
        operatingHours:
            result['operatingHours'] as Map<String, Map<String, String>>,
        is24Hours: result['is24Hours'] as bool,
        resetTime: result['resetTime'] as String,
      );
      await vm.updateStoreSettings(updatedSettings);

      if (context.mounted) {
        if (vm.errorMessage != null) {
          ToastWidget.show(context, vm.errorMessage!, type: ToastType.error);
        } else if (vm.successMessage != null) {
          ToastWidget.show(context, vm.successMessage!,
              type: ToastType.success);
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
          ToastWidget.show(context, vm.errorMessage!, type: ToastType.error);
        } else if (vm.successMessage != null) {
          ToastWidget.show(context, vm.successMessage!,
              type: ToastType.success);
          vm.clearSuccessMessage();
        }
      }
    }
  }
}
