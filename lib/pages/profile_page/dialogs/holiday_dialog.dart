import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/store_settings.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';

// 休業日設定のためのダイアログウィジェット
class HolidayDialog extends StatefulWidget {
  final ClosedDays initialClosedDays;

  const HolidayDialog({super.key, required this.initialClosedDays});

  @override
  _HolidayDialogState createState() => _HolidayDialogState();
}

class _HolidayDialogState extends State<HolidayDialog> {
  // 状態管理変数
  late bool _publicHolidayEnabled;
  late List<String> _selectedWeekdays;
  late List<int> _selectedMonthDays;
  late List<DateTime> _selectedSpecificDates;
  DateTime _focusedDay = DateTime.now();

  // ドロップダウン時、値を選択するための一時的な変数
  late String _tempWeekday;
  late int _tempMonthDay;

  // Data lists
  final List<String> _weekdays = ['月', '火', '水', '木', '金', '土', '日'];
  final List<int> _monthDays = List.generate(31, (i) => i + 1);

  // 曜日を日本語に変換するためのヘルパーマップ
  static const Map<int, String> _weekdayStringMap = {
    DateTime.monday: '月',
    DateTime.tuesday: '火',
    DateTime.wednesday: '水',
    DateTime.thursday: '木',
    DateTime.friday: '金',
    DateTime.saturday: '土',
    DateTime.sunday: '日',
  };

  @override
  void initState() {
    super.initState();
    final closedDays = widget.initialClosedDays;
    _publicHolidayEnabled = closedDays.holidayClosure;
    _selectedWeekdays = List.from(closedDays.regularWeekly);
    // int.tryParse を使用し、数字ではない値が入ってもアプリがクラッシュされないようにする
    _selectedMonthDays = closedDays.regularMonthly
        .map((dayStr) => int.tryParse(dayStr))
        .whereType<int>() // Parsing に失敗した null 値を除外
        .toList();
    _selectedSpecificDates = closedDays.specificDates
        .map((dateStr) {
          try {
            return DateTime.parse(dateStr);
          } catch (e) {
            return null;
          }
        })
        .whereType<DateTime>()
        .toList();

    _tempWeekday = _weekdays.first;
    _tempMonthDay = _monthDays.first;
  }

  // 週ごとの休業日や月ごとの休業日をチェックするヘルパーメソッド
  bool _isRegularClosedDay(DateTime day) {
    final isWeeklyHoliday =
        _selectedWeekdays.contains(_weekdayStringMap[day.weekday]);
    final isMonthlyHoliday = _selectedMonthDays.contains(day.day);
    return isWeeklyHoliday || isMonthlyHoliday;
  }

  // ユーザーがカレンダーの日付をタップしたときの処理
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      if (_isRegularClosedDay(selectedDay)) {
        return;
      }

      if (_selectedSpecificDates.any((d) => isSameDay(d, selectedDay))) {
        _selectedSpecificDates.removeWhere((d) => isSameDay(d, selectedDay));
      } else {
        _selectedSpecificDates.add(selectedDay);
      }
      _focusedDay = focusedDay;
    });
  }

  // 設定確認後の処理
  void _submit() {
    final result = ClosedDays(
      holidayClosure: _publicHolidayEnabled,
      regularWeekly: _selectedWeekdays,
      regularMonthly: _selectedMonthDays.map((d) => d.toString()).toList(),
      specificDates: _selectedSpecificDates
          .map((d) => d.toIso8601String().split('T').first)
          .toList(),
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    const desktopMaxWidth = 800.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth * 0.95 < desktopMaxWidth)
        ? screenWidth * 0.95
        : desktopMaxWidth;

    return BaseDialog(
      title: '休業日設定',
      width: dialogWidth,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LayoutBuilderを使用し、反応型レイアウトを適用
          LayoutBuilder(
            builder: (context, constraints) {
              const double mobileBreakpoint = 700;
              final bool isMobileLayout =
                  constraints.maxWidth < mobileBreakpoint;

              // mobile layout
              if (isMobileLayout) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 400, // カレンダーの高さを固定
                      child: _buildCalendarView(isMobile: true),
                    ),
                    const Divider(height: 32, color: AppColors.border),
                    _buildSettingsPanel(isMobile: true),
                  ],
                );
              }
              // desktop layout
              else {
                return SizedBox(
                  height: 400,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildCalendarView(isMobile: false),
                      ),
                      const VerticalDivider(width: 32, color: AppColors.border),
                      Expanded(
                        flex: 2,
                        child: _buildSettingsPanel(isMobile: false),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: AppColors.textPrimaryLight,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 80),
            ),
            onPressed: _submit,
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  // 左側に表示するウィジェット (Calendar 側)
  Widget _buildCalendarView({required bool isMobile}) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: _focusedDay,
      onDaySelected: _onDaySelected,
      selectedDayPredicate: (day) =>
          _selectedSpecificDates.any((d) => isSameDay(d, day)),
      headerStyle:
          const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          if (_isRegularClosedDay(day)) {
            return Center(
              child: Text(
                '${day.day}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return null;
        },
        todayBuilder: (context, day, focusedDay) {
          if (_isRegularClosedDay(day)) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          return null;
        },
        disabledBuilder: (context, day, focusedDay) {
          if (_isRegularClosedDay(day)) {
            return Center(
              child: Text(
                '${day.day}',
                style: TextStyle(color: Colors.red.withOpacity(0.5)),
              ),
            );
          }
          return null;
        },
      ),
    );
  }

  /// 右側の設定パネルを構築するメソッド (値選択側)
  Widget _buildSettingsPanel({required bool isMobile}) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: isMobile ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('定期休業日', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildChipSelector<String>(
            title: '毎週 (曜日)',
            items: _weekdays,
            selectedItems: _selectedWeekdays,
            tempValue: _tempWeekday,
            onTempChanged: (v) => setState(() => _tempWeekday = v!),
            onAdd: () => setState(() {
              if (!_selectedWeekdays.contains(_tempWeekday)) {
                _selectedWeekdays.add(_tempWeekday);
              }
            }),
            onDelete: (item) => setState(() => _selectedWeekdays.remove(item)),
          ),
          const SizedBox(height: 16),
          _buildChipSelector<int>(
            title: '毎月 (日)',
            items: _monthDays,
            selectedItems: _selectedMonthDays,
            tempValue: _tempMonthDay,
            itemToString: (item) => '$item日',
            onTempChanged: (v) => setState(() => _tempMonthDay = v!),
            onAdd: () => setState(() {
              if (!_selectedMonthDays.contains(_tempMonthDay)) {
                _selectedMonthDays.add(_tempMonthDay);
                _selectedMonthDays.sort(); // ソートして順序を保つ
              }
            }),
            onDelete: (item) => setState(() => _selectedMonthDays.remove(item)),
          ),
          const Divider(height: 32),
          Row(
            children: [
              const Text('祝日休業', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Switch(
                value: _publicHolidayEnabled,
                onChanged: (v) => setState(() => _publicHolidayEnabled = v),
                activeColor: AppColors.accentPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // チップセレクターを構築するヘルパーメソッド
  // タイトル、アイテムリスト、選択されたアイテム、追加・削除のコールバックを受け取る
  // アイテムの表示方法をカスタマイズするためのオプションも提供
  Widget _buildChipSelector<T>({
    required String title,
    required List<T> items,
    required List<T> selectedItems,
    required T tempValue,
    required ValueChanged<T?> onTempChanged,
    required VoidCallback onAdd,
    required ValueChanged<T> onDelete,
    String Function(T)? itemToString,
  }) {
    // itemToString が提供されていない場合は、デフォルトの toString() を使用
    final displayValue = itemToString ?? (item) => item.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        Wrap(
          spacing: 4,
          children: selectedItems
              .map((item) => Chip(
                    label: Text(displayValue(item)),
                    onDeleted: () => onDelete(item),
                  ))
              .toList(),
        ),
        Row(
          children: [
            DropdownButton<T>(
              value: tempValue,
              items: items
                  .map((i) =>
                      DropdownMenuItem(value: i, child: Text(displayValue(i))))
                  .toList(),
              onChanged: onTempChanged,
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: selectedItems.contains(tempValue) ? null : onAdd,
              child: const Text('追加'),
            ),
          ],
        ),
      ],
    );
  }
}
