import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'setting_section_widgets.dart';

class OperationSettings extends StatelessWidget {
  final VoidCallback showBusinessHoursDialog;
  const OperationSettings({super.key, required this.showBusinessHoursDialog});

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
                buildSettingItem('営業時間', '平日/週末時間帯設定', null, onTap: showBusinessHoursDialog),
                buildSettingItem('休業日', '休業日設定', null, onTap: () => _showHolidayDialog(context)),
              ],
            ),
          ),
          // const SizedBox(height: 24),
          // buildSectionTitle('お知らせ'),
          // sectionBox(
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       buildSettingItem('お知らせ方式', 'SMS, アッププッシュ, E-mail', null, onTap: () {}),
          //       buildSettingItem('お客様お知らせ', '状態変更時お知らせ活性化', Switch(value: false, onChanged: (value) {})),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  void _showHolidayDialog(BuildContext context) async {
    // bool regularHolidayEnabled = false;
    bool publicHolidayEnabled = false;
    String selectedWeekday = '月';
    int selectedMonthDay = 1;
    DateTime? selectedDate;
    final List<String> weekdays = ['月', '火', '水', '木', '金', '土', '日'];

    // 복수 선택을 위한 리스트로 변경
    List<String> selectedWeekdays = [];
    List<int> selectedMonthDays = [];
    String tempWeekday = weekdays[0];
    int tempMonthDay = 1;

    // 이번달 일자 리스트
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    List<int> specialDays = List.generate(daysInMonth, (i) => i + 1);
    List<int> selectedSpecialDays = [];
    int tempSpecialDay = 1;

    // 일본 2025년 공휴일 예시 (실제 서비스에서는 더 많은 날짜 필요)
    final Set<DateTime> jpHolidays = {
      DateTime(2025, 1, 1),   // 元日
      DateTime(2025, 1, 13),  // 成人の日
      DateTime(2025, 2, 11),  // 建国記念の日
      DateTime(2025, 2, 23),  // 天皇誕生日
      DateTime(2025, 3, 21),  // 春分の日
      DateTime(2025, 4, 29),  // 昭和の日
      DateTime(2025, 5, 3),   // 憲法記念日
      DateTime(2025, 5, 4),   // みどりの日
      DateTime(2025, 5, 5),   // こどもの日
      DateTime(2025, 7, 21),  // 海の日
      DateTime(2025, 9, 15),  // 敬老の日
      DateTime(2025, 9, 23),  // 秋分の日
      DateTime(2025, 10, 13), // 体育の日
      DateTime(2025, 11, 3),  // 文化の日
      DateTime(2025, 11, 23), // 勤労感謝の日
    };

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('休業日設定', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
          content: SizedBox(
            width: 800,
            height: 400,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 좌측: 달력
                Expanded(
                  flex: 1,
                  child: TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2100),
                    focusedDay: selectedDate ?? DateTime.now(),
                    selectedDayPredicate: (day) => selectedDate != null && isSameDay(day, selectedDate),
                    onDaySelected: (selected, _) {
                      setDialogState(() {
                        selectedDate = selected;
                      });
                    },
                    calendarFormat: CalendarFormat.month,
                    headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final isHoliday = publicHolidayEnabled && jpHolidays.any((h) => isSameDay(h, day));
                        final isRegularWeekday = selectedWeekdays.contains(weekdays[day.weekday - 1]);
                        final isRegularMonthDay = selectedMonthDays.contains(day.day);
                        final isSpecialDay = day.year == now.year && day.month == now.month && selectedSpecialDays.contains(day.day);
                        final isRed = isHoliday || isRegularWeekday || isRegularMonthDay || isSpecialDay;
                        return Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(color: isRed ? Colors.red : null),
                          ),
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        final isHoliday = publicHolidayEnabled && jpHolidays.any((h) => isSameDay(h, day));
                        final isRegularWeekday = selectedWeekdays.contains(weekdays[day.weekday - 1]);
                        final isRegularMonthDay = selectedMonthDays.contains(day.day);
                        final isSpecialDay = day.year == now.year && day.month == now.month && selectedSpecialDays.contains(day.day);
                        final isRed = isHoliday || isRegularWeekday || isRegularMonthDay || isSpecialDay;
                        return Container(
                          decoration: BoxDecoration(
                            color: isRed ? Colors.red[100] : Colors.blue[100],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(color: isRed ? Colors.red : Colors.blue),
                            ),
                          ),
                        );
                      },
                      selectedBuilder: (context, day, focusedDay) {
                        final isHoliday = publicHolidayEnabled && jpHolidays.any((h) => isSameDay(h, day));
                        final isRegularWeekday = selectedWeekdays.contains(weekdays[day.weekday - 1]);
                        final isRegularMonthDay = selectedMonthDays.contains(day.day);
                        final isSpecialDay = day.year == now.year && day.month == now.month && selectedSpecialDays.contains(day.day);
                        final isRed = isHoliday || isRegularWeekday || isRegularMonthDay || isSpecialDay;
                        return Container(
                          decoration: BoxDecoration(
                            color: isRed ? Colors.red : Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 구분선 추가
                Container(
                  width: 1,
                  height: 500,
                  color: Colors.grey[300],
                ),
                const SizedBox(width: 32),
                // 우측: 설정 UI
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 특정일 지정
                        const Text('特定日指定', style: TextStyle(fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: selectedSpecialDays.map((d) => Chip(
                            label: Text('$d日'),
                            onDeleted: () => setDialogState(() => selectedSpecialDays.remove(d)),
                          )).toList(),
                        ),
                        Row(
                          children: [
                            DropdownButton<int>(
                              value: tempSpecialDay,
                              items: specialDays.map((d) => DropdownMenuItem(value: d, child: Text('$d日'))).toList(),
                              onChanged: (v) => setDialogState(() => tempSpecialDay = v!),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: selectedSpecialDays.contains(tempSpecialDay)
                                ? null
                                : () => setDialogState(() => selectedSpecialDays.add(tempSpecialDay)),
                              child: const Text('追加'),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        // 정기휴업일
                        const Text('定期休業日', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('毎週(曜日)', style: TextStyle()),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: selectedWeekdays.map((w) => Chip(
                            label: Text(w),
                            onDeleted: () => setDialogState(() => selectedWeekdays.remove(w)),
                          )).toList(),
                        ),
                        Row(
                          children: [
                            DropdownButton<String>(
                              value: tempWeekday,
                              items: weekdays.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                              onChanged: (v) => setDialogState(() => tempWeekday = v!),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: selectedWeekdays.contains(tempWeekday)
                                ? null
                                : () => setDialogState(() => selectedWeekdays.add(tempWeekday)),
                              child: const Text('追加'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('毎月(日付)', style: TextStyle()),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: selectedMonthDays.map((d) => Chip(
                            label: Text('$d日'),
                            onDeleted: () => setDialogState(() => selectedMonthDays.remove(d)),
                          )).toList(),
                        ),
                        Row(
                          children: [
                            DropdownButton<int>(
                              value: tempMonthDay,
                              items: List.generate(31, (i) => DropdownMenuItem(value: i+1, child: Text('${i+1}日'))),
                              onChanged: (v) => setDialogState(() => tempMonthDay = v!),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: selectedMonthDays.contains(tempMonthDay)
                                ? null
                                : () => setDialogState(() => selectedMonthDays.add(tempMonthDay)),
                              child: const Text('追加'),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        // 공휴일 휴일 지정
                        Row(
                          children: [
                            const Text('祝日休業', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Switch(
                              value: publicHolidayEnabled,
                              onChanged: (v) => setDialogState(() => publicHolidayEnabled = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Color(0xFF263238))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F61),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // TODO: 실제 저장 로직 구현
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('休業日が設定されました。')),
                );
              },
              child: const Text('確認'),
            ),
          ],
        ),
      ),
    );
  }
}
