import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';
// import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

// 営業時間設定のためのダイアログウィジェット
// 営業時間設定のためのダイアログウィジェット
class BusinessHoursDialog extends StatefulWidget {
  final Map<String, Map<String, String>> initialHours;
  final bool initialIs24Hours;
  final String initialResetTime;

  const BusinessHoursDialog({
    super.key,
    required this.initialHours,
    this.initialIs24Hours = false,
    this.initialResetTime = "06:00",
  });

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
  late bool _is24Hours;
  late int _resetHour;
  late int _resetMinute;

  @override
  void initState() {
    super.initState();
    _businessHours = _convertInitialHours(widget.initialHours);
    _is24Hours = widget.initialIs24Hours;

    List<int> resetParts;
    try {
      if (widget.initialResetTime.isEmpty ||
          !widget.initialResetTime.contains(':')) {
        throw FormatException('Invalid format');
      }
      resetParts = widget.initialResetTime.split(':').map(int.parse).toList();
    } catch (_) {
      resetParts = [6, 0];
    }

    _resetHour = resetParts[0];
    _resetMinute = resetParts.length > 1 ? resetParts[1] : 0;
  }

  Map<String, Map<String, int>> _convertInitialHours(
      Map<String, Map<String, String>> hours) {
    final converted = <String, Map<String, int>>{};
    for (var key in _dayKeys) {
      final start = (hours[key]?['start']?.contains(':') ?? false)
          ? hours[key]!['start']!
          : '09:00';
      final end = (hours[key]?['end']?.contains(':') ?? false)
          ? hours[key]!['end']!
          : '22:00';

      List<int> startParts;
      List<int> endParts;

      try {
        startParts = start.split(':').map(int.parse).toList();
      } catch (_) {
        startParts = [9, 0];
      }

      try {
        endParts = end.split(':').map(int.parse).toList();
      } catch (_) {
        endParts = [22, 0];
      }

      converted[key] = {
        'startHour': startParts[0],
        'startMinute': startParts.length > 1 ? startParts[1] : 0,
        'endHour': endParts[0],
        'endMinute': endParts.length > 1 ? endParts[1] : 0,
      };
    }
    return converted;
  }

  Map<String, dynamic> _packageResult() {
    final hoursResult = <String, Map<String, String>>{};
    for (var key in _dayKeys) {
      final hours = _businessHours[key]!;
      hoursResult[key] = {
        'start':
            '${hours['startHour'].toString().padLeft(2, '0')}:${hours['startMinute'].toString().padLeft(2, '0')}',
        'end':
            '${hours['endHour'].toString().padLeft(2, '0')}:${hours['endMinute'].toString().padLeft(2, '0')}',
      };
    }

    return {
      'operatingHours': hoursResult,
      'is24Hours': _is24Hours,
      'resetTime':
          '${_resetHour.toString().padLeft(2, '0')}:${_resetMinute.toString().padLeft(2, '0')}',
    };
  }

  // ユーザーが時間を選択した後の確認ボタンの処理
  void _submit() {
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
      content: SizedBox(
        height: 400, // 固定高さを与えてスクロール可能に
        child: Column(
          children: [
            // 24時間営業スイッチ
            SwitchListTile(
              title: const Text('24時間営業',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('営業終了時間がなく、指定時間に毎日リセットされます'),
              value: _is24Hours,
              activeColor: AppColors.accentPrimary,
              onChanged: (value) {
                setState(() {
                  _is24Hours = value;
                });
              },
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_is24Hours) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'データリセット時間',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '毎日この時間に待機リストとQRコードが更新されます',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimeDropdown(_resetHour,
                              (v) => setState(() => _resetHour = v!), true),
                          const SizedBox(width: 8),
                          const Text(':',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          _buildTimeDropdown(_resetMinute,
                              (v) => setState(() => _resetMinute = v!), false),
                        ],
                      ),
                    ] else ...[
                      ...List.generate(_dayKeys.length, (index) {
                        final dayKey = _dayKeys[index];
                        return _TimePickerRow(
                          dayLabel: _dayLabels[index],
                          hours: _businessHours[dayKey]!,
                          onChanged: (newHours) =>
                              setState(() => _businessHours[dayKey] = newHours),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildTimeDropdown(
      int value, ValueChanged<int?>? onValueChange, bool isHour) {
    final items = isHour
        ? List.generate(
            24,
            (i) => DropdownMenuItem(
                value: i, child: Text(i.toString().padLeft(2, '0'))))
        : List.generate(
            4,
            (i) => DropdownMenuItem(
                value: i * 15,
                child: Text((i * 15).toString().padLeft(2, '0'))));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<int>(
        value: value,
        items: items,
        onChanged: onValueChange,
        underline: const SizedBox(),
        icon:
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
        style: const TextStyle(
            color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
        isDense: true,
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Day Label Circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              dayLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Time Pickers
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Start Time
                _buildTimeGroup(
                  hours['startHour']!,
                  hours['startMinute']!,
                  (val) => onChanged({...hours, 'startHour': val}),
                  (val) => onChanged({...hours, 'startMinute': val}),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child:
                      Text('~', style: TextStyle(color: Colors.grey.shade400)),
                ),

                // End Time
                _buildTimeGroup(
                  hours['endHour']!,
                  hours['endMinute']!,
                  (val) => onChanged({...hours, 'endHour': val}),
                  (val) => onChanged({...hours, 'endMinute': val}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build Hour:Minute group
  Widget _buildTimeGroup(int hour, int minute, ValueChanged<int> onHour,
      ValueChanged<int> onMinute) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactDropdown(hour, onHour, true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: const Text(':',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        _buildCompactDropdown(minute, onMinute, false),
      ],
    );
  }

  Widget _buildCompactDropdown(
      int value, ValueChanged<int> onValueChange, bool isHour) {
    final items = isHour
        ? List.generate(
            24,
            (i) => DropdownMenuItem(
                value: i, child: Text(i.toString().padLeft(2, '0'))))
        : List.generate(
            4,
            (i) => DropdownMenuItem(
                value: i * 15,
                child: Text((i * 15).toString().padLeft(2, '0'))));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<int>(
        value: value,
        items: items,
        onChanged: (v) => onValueChange(v!),
        underline: const SizedBox(), // Remove underline
        icon: const SizedBox.shrink(), // Remove icon for compactness
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        alignment: Alignment.center,
        isDense: true,
      ),
    );
  }
}
