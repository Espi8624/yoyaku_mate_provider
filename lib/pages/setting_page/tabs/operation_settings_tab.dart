import 'package:flutter/material.dart';
import '../widgets/setting_section.dart';
import '../dialogs/holiday_dialog.dart';
import '../dialogs/business_hours_dialog.dart';
import '../../../models/store_settings.dart';
import '../../../widgets/common_widgets/custom_snack_bar.dart';

// 運営設定タブのUIを構成するウィジェット
class OperationSettingsTab extends StatelessWidget {
  final StoreSettings storeSettings;
  final ValueChanged<StoreSettings> onChanged;

  const OperationSettingsTab({
    super.key,
    required this.storeSettings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('営業日及び時間'),
          sectionBox(
            child: Column(
              children: [
                buildSettingItem(
                  title: '営業時間',
                  subtitle:
                      _buildBusinessHoursSummary(storeSettings.operatingHours),
                  onTap: () => _showBusinessHoursDialog(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                buildSettingItem(
                  title: '休業日',
                  subtitle: storeSettings
                      .closedDays.summary, // モデルにsummaryプロパティを追加し、要約情報を表示
                  onTap: () => _showHolidayDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildBusinessHoursSummary(Map<String, Map<String, String>> hours) {
    final weekdayHours =
        '${hours['monday']?['start'] ?? ''}-${hours['monday']?['end'] ?? ''}';
    return '平日: $weekdayHours'; // 設定内容表示
  }

  void _showBusinessHoursDialog(BuildContext context) async {
    final result = await showDialog<Map<String, Map<String, String>>>(
      context: context,
      builder: (_) =>
          BusinessHoursDialog(initialHours: storeSettings.operatingHours),
    );
    if (result != null) {
      onChanged(storeSettings.copyWith(operatingHours: result));
      CustomSnackBar.show(context,
          message: '営業時間が設定されました', status: SnackBarStatus.info);
    }
  }

  void _showHolidayDialog(BuildContext context) async {
    final result = await showDialog<ClosedDays>(
      context: context,
      builder: (_) =>
          HolidayDialog(initialClosedDays: storeSettings.closedDays),
    );
    if (result != null) {
      onChanged(storeSettings.copyWith(closedDays: result));
      CustomSnackBar.show(context,
          message: '休業日が設定されました', status: SnackBarStatus.info);
    }
  }
}
