import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

// 営業時間設定のためのダイアログウィジェット
class BusinessHoursDialog extends StatefulWidget {
  final Map<String, Map<String, String>> initialHours;

  const BusinessHoursDialog({super.key, required this.initialHours});

  @override
  State<BusinessHoursDialog> createState() => _BusinessHoursDialogState();
}

class _BusinessHoursDialogState extends State<BusinessHoursDialog> {
  final _dayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];
  final _dayLabels = ['月', '火', '水', '木', '金', '土', '日'];
  late Map<String, Map<String, int>> _businessHours;

  @override
  void initState() {
    super.initState();
    _businessHours = _convertInitialHours(widget.initialHours);
  }

  Map<String, Map<String, int>> _convertInitialHours(
      Map<String, Map<String, String>> hours) {
    final converted = <String, Map<String, int>>{};
    for (var key in _dayKeys) {
      final start = hours[key]?['start'] ?? '09:00';
      final end = hours[key]?['end'] ?? '22:00';
      final startParts = start.split(':').map(int.parse).toList();
      final endParts = end.split(':').map(int.parse).toList();
      converted[key] = {
        'startHour': startParts[0],
        'startMinute': startParts[1],
        'endHour': endParts[0],
        'endMinute': endParts[1],
      };
    }
    return converted;
  }

  Map<String, Map<String, String>> _packageResult() {
    final result = <String, Map<String, String>>{};
    for (var key in _dayKeys) {
      final hours = _businessHours[key]!;
      result[key] = {
        'start':
            '${hours['startHour'].toString().padLeft(2, '0')}:${hours['startMinute'].toString().padLeft(2, '0')}',
        'end':
            '${hours['endHour'].toString().padLeft(2, '0')}:${hours['endMinute'].toString().padLeft(2, '0')}',
      };
    }
    return result;
  }

  // ユーザーが時間を選択した後の確認ボタンの処理
  void _submit() {
    for (var key in _dayKeys) {
      final times = _businessHours[key]!;
      final start = times['startHour']! * 60 + times['startMinute']!;
      final end = times['endHour']! * 60 + times['endMinute']!;
      if (start >= end) {
        ToastWidget.show(context, '閉店時間は開店時間より早く設定できません。',
            type: ToastType.error);
        return;
      }
    }
    Navigator.of(context).pop(_packageResult());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const desktopMaxWidth = 470.0;
    final dialogWidth = (screenWidth * 0.9 < desktopMaxWidth)
        ? screenWidth * 0.9
        : desktopMaxWidth;

    return BaseDialog(
      title: '営業時間設定',
      width: dialogWidth,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(_dayKeys.length, (index) {
            final dayKey = _dayKeys[index];
            return _TimePickerRow(
              dayLabel: _dayLabels[index],
              hours: _businessHours[dayKey]!,
              onChanged: (newHours) =>
                  setState(() => _businessHours[dayKey] = newHours),
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                foregroundColor: AppColors.textPrimaryLight,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _submit,
              child: const Text('確認'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  final String dayLabel;
  final Map<String, int> hours;
  final ValueChanged<Map<String, int>> onChanged;

  const _TimePickerRow(
      {required this.dayLabel, required this.hours, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
              width: 30,
              child: Text(dayLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          _buildTimeDropdown(hours['startHour']!,
              (v) => onChanged({...hours, 'startHour': v!}), true),
          const SizedBox(width: 4),
          _buildTimeDropdown(hours['startMinute']!,
              (v) => onChanged({...hours, 'startMinute': v!}), false),
          const Text(' ~ '),
          _buildTimeDropdown(hours['endHour']!,
              (v) => onChanged({...hours, 'endHour': v!}), true),
          const SizedBox(width: 4),
          _buildTimeDropdown(hours['endMinute']!,
              (v) => onChanged({...hours, 'endMinute': v!}), false),
        ],
      ),
    );
  }

  Widget _buildTimeDropdown(
      int value, ValueChanged<int?>? onValueChange, bool isHour) {
    final items = isHour
        ? List.generate(
            24, (i) => DropdownMenuItem(value: i, child: Text('$i時')))
        : List.generate(4,
            (i) => DropdownMenuItem(value: i * 15, child: Text('${i * 15}分')));

    return Expanded(
      child: DropdownButton<int>(
        value: value,
        items: items,
        onChanged: onValueChange,
        isExpanded: true,
        underline: Container(height: 1, color: AppColors.textPrimary),
      ),
    );
  }
}
