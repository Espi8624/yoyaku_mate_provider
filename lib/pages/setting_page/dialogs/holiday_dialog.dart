import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../widgets/custom_snack_bar.dart';

Future<void> showHolidayDialog({
  required BuildContext context,
  required List<String> weekdays,
  required List<String> selectedWeekdays,
  required List<int> selectedMonthDays,
  required List<int> specialDays,
  required List<int> selectedSpecialDays,
  required Set<DateTime> jpHolidays,
  required bool publicHolidayEnabled,
  required DateTime? selectedDate,
  required Function(void Function()) setDialogState,
  required int tempSpecialDay,
  required String tempWeekday,
  required int tempMonthDay,
  required DateTime now,
  required void Function({
    required bool publicHolidayEnabled,
    required List<String> selectedWeekdays,
    required List<int> selectedMonthDays,
    required List<int> selectedSpecialDays,
  }) onConfirm,
}) async {
  bool publicHolidayEnabled0 = publicHolidayEnabled;
  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('休業日設定',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238))),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF263238)),
              onPressed: () => Navigator.pop(context),
              splashRadius: 20,
              tooltip: '閉じる',
            ),
          ],
        ),
        content: SizedBox(
          width: 800,
          height: 400,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左側: カレンダー
              Expanded(
                flex: 1,
                child: TableCalendar(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2100),
                  focusedDay: selectedDate ?? DateTime.now(),
                  selectedDayPredicate: (day) =>
                      selectedDate != null && isSameDay(day, selectedDate),
                  onDaySelected: (selected, _) {
                    setDialogState(() {
                      selectedDate = selected;
                    });
                  },
                  calendarFormat: CalendarFormat.month,
                  headerStyle: const HeaderStyle(
                      formatButtonVisible: false, titleCentered: true),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final isHoliday = publicHolidayEnabled &&
                          jpHolidays.any((h) => isSameDay(h, day));
                      final isRegularWeekday =
                          selectedWeekdays.contains(weekdays[day.weekday - 1]);
                      final isRegularMonthDay =
                          selectedMonthDays.contains(day.day);
                      final isSpecialDay = day.year == now.year &&
                          day.month == now.month &&
                          selectedSpecialDays.contains(day.day);
                      final isRed = isHoliday ||
                          isRegularWeekday ||
                          isRegularMonthDay ||
                          isSpecialDay;
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(color: isRed ? Colors.red : null),
                        ),
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      final isHoliday = publicHolidayEnabled &&
                          jpHolidays.any((h) => isSameDay(h, day));
                      final isRegularWeekday =
                          selectedWeekdays.contains(weekdays[day.weekday - 1]);
                      final isRegularMonthDay =
                          selectedMonthDays.contains(day.day);
                      final isSpecialDay = day.year == now.year &&
                          day.month == now.month &&
                          selectedSpecialDays.contains(day.day);
                      final isRed = isHoliday ||
                          isRegularWeekday ||
                          isRegularMonthDay ||
                          isSpecialDay;
                      return Container(
                        decoration: BoxDecoration(
                          color: isRed ? Colors.red[100] : Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                                color: isRed ? Colors.red : Colors.blue),
                          ),
                        ),
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      final isHoliday = publicHolidayEnabled &&
                          jpHolidays.any((h) => isSameDay(h, day));
                      final isRegularWeekday =
                          selectedWeekdays.contains(weekdays[day.weekday - 1]);
                      final isRegularMonthDay =
                          selectedMonthDays.contains(day.day);
                      final isSpecialDay = day.year == now.year &&
                          day.month == now.month &&
                          selectedSpecialDays.contains(day.day);
                      final isRed = isHoliday ||
                          isRegularWeekday ||
                          isRegularMonthDay ||
                          isSpecialDay;
                      return Container(
                        decoration: BoxDecoration(
                          color: isRed ? Colors.red : Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 区分線
              Container(
                width: 1,
                height: 500,
                color: Colors.grey[300],
              ),
              const SizedBox(width: 32),
              // 右側: 設定 UI
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 特定日指定
                      const Text('特定日指定',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: selectedSpecialDays
                            .map((d) => Chip(
                                  label: Text('$d日'),
                                  onDeleted: () => setDialogState(
                                      () => selectedSpecialDays.remove(d)),
                                ))
                            .toList(),
                      ),
                      Row(
                        children: [
                          DropdownButton<int>(
                            value: tempSpecialDay,
                            items: specialDays
                                .map((d) => DropdownMenuItem(
                                    value: d, child: Text('$d日')))
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => tempSpecialDay = v!),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: selectedSpecialDays
                                    .contains(tempSpecialDay)
                                ? null
                                : () => setDialogState(() =>
                                    selectedSpecialDays.add(tempSpecialDay)),
                            child: const Text('追加'),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      // 定期休業日
                      const Text('定期休業日',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('毎週(曜日)', style: TextStyle()),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: selectedWeekdays
                            .map((w) => Chip(
                                  label: Text(w),
                                  onDeleted: () => setDialogState(
                                      () => selectedWeekdays.remove(w)),
                                ))
                            .toList(),
                      ),
                      Row(
                        children: [
                          DropdownButton<String>(
                            value: tempWeekday,
                            items: weekdays
                                .map((w) =>
                                    DropdownMenuItem(value: w, child: Text(w)))
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => tempWeekday = v!),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: selectedWeekdays.contains(tempWeekday)
                                ? null
                                : () => setDialogState(
                                    () => selectedWeekdays.add(tempWeekday)),
                            child: const Text('追加'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('毎月(日付)', style: TextStyle()),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: selectedMonthDays
                            .map((d) => Chip(
                                  label: Text('$d日'),
                                  onDeleted: () => setDialogState(
                                      () => selectedMonthDays.remove(d)),
                                ))
                            .toList(),
                      ),
                      Row(
                        children: [
                          DropdownButton<int>(
                            value: tempMonthDay,
                            items: List.generate(
                                31,
                                (i) => DropdownMenuItem(
                                    value: i + 1, child: Text('${i + 1}日'))),
                            onChanged: (v) =>
                                setDialogState(() => tempMonthDay = v!),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: selectedMonthDays.contains(tempMonthDay)
                                ? null
                                : () => setDialogState(
                                    () => selectedMonthDays.add(tempMonthDay)),
                            child: const Text('追加'),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      // 休業日指定
                      Row(
                        children: [
                          const Text('祝日休業',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Switch(
                            value: publicHolidayEnabled0,
                            onChanged: (v) =>
                                setDialogState(() => publicHolidayEnabled0 = v),
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
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actions: [
          FractionallySizedBox(
            widthFactor: 0.75,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F61),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.pop(context);
                onConfirm(
                  publicHolidayEnabled: publicHolidayEnabled0,
                  selectedWeekdays: selectedWeekdays,
                  selectedMonthDays: selectedMonthDays,
                  selectedSpecialDays: selectedSpecialDays,
                );
                CustomSnackBar.show(
                  context,
                  message: '休業日が設定されました',
                  status: SnackBarStatus.info,
                );
              },
              child: const Text('確認'),
            ),
          ),
        ],
      ),
    ),
  );
}
