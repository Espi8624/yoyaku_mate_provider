import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class StoreBusinessHoursStep extends StatefulWidget {
  final Function(Map<String, Map<String, String>> hours, bool is24Hours,
      String resetTime) onNext;

  const StoreBusinessHoursStep({
    super.key,
    required this.onNext,
  });

  @override
  State<StoreBusinessHoursStep> createState() => _StoreBusinessHoursStepState();
}

class _StoreBusinessHoursStepState extends State<StoreBusinessHoursStep> {
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
  bool _is24Hours = false;
  int _resetHour = 6;
  int _resetMinute = 0;

  @override
  void initState() {
    super.initState();
    // Default hours: 09:00 - 22:00
    _businessHours = {};
    for (var key in _dayKeys) {
      _businessHours[key] = {
        'startHour': 9,
        'startMinute': 0,
        'endHour': 22,
        'endMinute': 0,
      };
    }
  }

  void _handleNext() {
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

    final resetTime =
        '${_resetHour.toString().padLeft(2, '0')}:${_resetMinute.toString().padLeft(2, '0')}';

    widget.onNext(hoursResult, _is24Hours, resetTime);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '営業時間の設定',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'お店の営業時間を設定してください。\n24時間営業の場合はリセット時間を指定してください。',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('24時間営業',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('指定時間に毎日リセットされます'),
                  value: _is24Hours,
                  activeColor: AppColors.accentPrimary,
                  onChanged: (value) {
                    setState(() {
                      _is24Hours = value;
                    });
                  },
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_is24Hours) ...[
                          const SizedBox(height: 40),
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
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTimeDropdown(_resetHour,
                                  (v) => setState(() => _resetHour = v!), true),
                              const SizedBox(width: 8),
                              const Text(':',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              _buildTimeDropdown(
                                  _resetMinute,
                                  (v) => setState(() => _resetMinute = v!),
                                  false),
                            ],
                          ),
                        ] else ...[
                          ...List.generate(_dayKeys.length, (index) {
                            final dayKey = _dayKeys[index];
                            return _TimePickerRow(
                              dayLabel: _dayLabels[index],
                              hours: _businessHours[dayKey]!,
                              onChanged: (newHours) => setState(
                                  () => _businessHours[dayKey] = newHours),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _handleNext,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('次へ'),
          ),
        ),
      ],
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
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
        underline: const SizedBox(),
        icon: const SizedBox.shrink(),
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        alignment: Alignment.center,
        isDense: true,
      ),
    );
  }
}
