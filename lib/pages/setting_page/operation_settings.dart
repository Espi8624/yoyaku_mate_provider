import 'package:flutter/material.dart';
import 'widget/setting_section_widgets.dart';
import 'dialogs/holiday_dialog.dart';
import '../../models/store_settings.dart';

class OperationSettings extends StatelessWidget {
  final StoreSettings storeSettings;
  final ValueChanged<StoreSettings> onChanged;
  final VoidCallback showBusinessHoursDialog;
  const OperationSettings({
    super.key,
    required this.storeSettings,
    required this.onChanged,
    required this.showBusinessHoursDialog,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSettingItem(
                  '営業時間',
                  _buildBusinessHoursSummary(storeSettings.operatingHours),
                  null,
                  onTap: showBusinessHoursDialog,
                ),
                buildSettingItem(
                  '休業日',
                  _buildClosedDaysSummary(storeSettings.closedDays),
                  null,
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
    // 例: 月~金 09:00-18:00, 土/日 10:00-15:00
    final weekday = hours['monday']?['start'] == hours['friday']?['start'] && hours['monday']?['end'] == hours['friday']?['end']
      ? '月~金 ${hours['monday']?['start'] ?? ''}-${hours['monday']?['end'] ?? ''}' : '';
    final weekend = hours['saturday'] != null && hours['sunday'] != null
      ? '土/日 ${hours['saturday']?['start'] ?? ''}-${hours['saturday']?['end'] ?? ''}' : '';
    return [weekday, weekend].where((s) => s.isNotEmpty).join(', ');
  }

  String _buildClosedDaysSummary(ClosedDays closedDays) {
    final List<String> parts = [];
    if (closedDays.regularWeekly.isNotEmpty) {
      parts.add('定期休業日: ${closedDays.regularWeekly.join(", ")}');
    }
    if (closedDays.specificDates.isNotEmpty) {
      parts.add('特定休業日: ${closedDays.specificDates.join(", ")}');
    }
    if (closedDays.holidayClosure) {
      parts.add('祝日休業');
    }
    return parts.isEmpty ? 'なし' : parts.join(' / ');
  }

  void _showHolidayDialog(BuildContext context) async {
    final closedDays = storeSettings.closedDays;
    bool publicHolidayEnabled = closedDays.holidayClosure;
    DateTime? selectedDate;
    final List<String> weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    List<String> selectedWeekdays = List.from(closedDays.regularWeekly);
    List<int> selectedMonthDays = closedDays.regularMonthly.map((e) => int.tryParse(e) ?? 1).toList();
    String tempWeekday = selectedWeekdays.isNotEmpty ? selectedWeekdays.first : weekdays[0];
    int tempMonthDay = selectedMonthDays.isNotEmpty ? selectedMonthDays.first : 1;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    List<int> specialDays = List.generate(daysInMonth, (i) => i + 1);
    List<int> selectedSpecialDays = closedDays.specificDates.map((e) {
      final dt = DateTime.tryParse(e);
      return dt?.day;
    }).whereType<int>().toList();
    int tempSpecialDay = selectedSpecialDays.isNotEmpty ? selectedSpecialDays.first : 1;
    final Set<DateTime> jpHolidays = {
      DateTime(2025, 1, 1),
      DateTime(2025, 1, 13),
      DateTime(2025, 2, 11),
      DateTime(2025, 2, 23),
      DateTime(2025, 3, 21),
      DateTime(2025, 4, 29),
      DateTime(2025, 5, 3),
      DateTime(2025, 5, 4),
      DateTime(2025, 5, 5),
      DateTime(2025, 7, 21),
      DateTime(2025, 9, 15),
      DateTime(2025, 9, 23),
      DateTime(2025, 10, 13),
      DateTime(2025, 11, 3),
      DateTime(2025, 11, 23),
    };
    await showHolidayDialog(
      context: context,
      weekdays: weekdays,
      selectedWeekdays: selectedWeekdays,
      selectedMonthDays: selectedMonthDays,
      specialDays: specialDays,
      selectedSpecialDays: selectedSpecialDays,
      jpHolidays: jpHolidays,
      publicHolidayEnabled: publicHolidayEnabled,
      selectedDate: selectedDate,
      setDialogState: (fn) => fn(),
      tempSpecialDay: tempSpecialDay,
      tempWeekday: tempWeekday,
      tempMonthDay: tempMonthDay,
      now: now,
      onConfirm: ({
        required bool publicHolidayEnabled,
        required List<String> selectedWeekdays,
        required List<int> selectedMonthDays,
        required List<int> selectedSpecialDays,
      }) {
        final updatedClosedDays = ClosedDays(
          specificDates: selectedSpecialDays.map((d) {
            final date = DateTime(now.year, now.month, d);
            return date.toIso8601String().split('T').first;
          }).toList(),
          regularWeekly: List.from(selectedWeekdays),
          regularMonthly: selectedMonthDays.map((d) => d.toString()).toList(),
          holidayClosure: publicHolidayEnabled,
        );
        final updated = storeSettings.copyWith(closedDays: updatedClosedDays);
        onChanged(updated);
      },
    );
  }
}
