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
    // 예시: 월~금 09:00-18:00, 토/일 10:00-15:00
    final weekday = hours['monday']?['start'] == hours['friday']?['start'] && hours['monday']?['end'] == hours['friday']?['end']
      ? '월~금 ${hours['monday']?['start'] ?? ''}-${hours['monday']?['end'] ?? ''}' : '';
    final weekend = hours['saturday'] != null && hours['sunday'] != null
      ? '토/일 ${hours['saturday']?['start'] ?? ''}-${hours['saturday']?['end'] ?? ''}' : '';
    return [weekday, weekend].where((s) => s.isNotEmpty).join(', ');
  }

  String _buildClosedDaysSummary(ClosedDays closedDays) {
    final List<String> parts = [];
    if (closedDays.regularWeekly.isNotEmpty) {
      parts.add('정기휴무: ${closedDays.regularWeekly.join(", ")}');
    }
    if (closedDays.specificDates.isNotEmpty) {
      parts.add('특정일: ${closedDays.specificDates.join(", ")}');
    }
    if (closedDays.holidayClosure) {
      parts.add('공휴일 휴무');
    }
    return parts.isEmpty ? '없음' : parts.join(' / ');
  }

  void _showHolidayDialog(BuildContext context) async {
    // DB 값 반영: 실제 storeSettings.closedDays 값으로 초기화
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
      onConfirm: () {},
    );
  }
}
