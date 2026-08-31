import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/time_block.dart';
import '../../../models/store_settings.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';

// 勤務可能な曜日・時間帯を設定するためのダイアログウィジェット
// 曜日ごとに空リストの場合は「勤務不可」を意味する
class AvailabilityDialog extends StatefulWidget {
  final Map<String, dynamic> initialAvailability;
  // 店舗の営業時間設定(nullの場合は営業時間による制限をかけない)
  final StoreSettings? storeSettings;

  const AvailabilityDialog({
    super.key,
    required this.initialAvailability,
    this.storeSettings,
  });

  @override
  State<AvailabilityDialog> createState() => _AvailabilityDialogState();
}

class _AvailabilityDialogState extends State<AvailabilityDialog> {
  late Map<String, Set<String>> _availability;

  @override
  void initState() {
    super.initState();
    _availability = {
      for (final day in Weekday.values)
        day: (widget.initialAvailability[day] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toSet() ??
            <String>{},
    };
  }

  Map<String, List<String>> _packageResult() {
    return {
      for (final entry in _availability.entries) entry.key: entry.value.toList(),
    };
  }

  void _submit() {
    Navigator.of(context).pop(_packageResult());
  }

  void _toggleBlock(String day, String block) {
    setState(() {
      final blocks = _availability[day]!;
      if (blocks.contains(block)) {
        blocks.remove(block);
      } else {
        blocks.add(block);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const desktopMaxWidth = 470.0;
    final dialogWidth = (screenWidth * 0.9 < desktopMaxWidth)
        ? screenWidth * 0.9
        : desktopMaxWidth;

    return BaseDialog(
      title: '勤務可能時間の設定',
      width: dialogWidth,
      content: SizedBox(
        height: 420,
        child: Column(
          children: [
            const Text(
              '勤務可能な曜日・時間帯を選択してください。選択がない曜日は勤務不可として扱われます。',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(Weekday.values.length, (index) {
                    final day = Weekday.values[index];
                    final dayLabel = Weekday.labels[index];
                    final hours = widget.storeSettings?.operatingHours[day];
                    return _AvailabilityRow(
                      dayLabel: dayLabel,
                      selectedBlocks: _availability[day]!,
                      onToggle: (block) => _toggleBlock(day, block),
                      is24Hours: widget.storeSettings?.is24Hours ?? false,
                      isClosed:
                          widget.storeSettings?.closedDays.isClosedOn(dayLabel) ??
                              false,
                      businessStart: hours?['start'],
                      businessEnd: hours?['end'],
                    );
                  }),
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
}

class _AvailabilityRow extends StatelessWidget {
  final String dayLabel;
  final Set<String> selectedBlocks;
  final ValueChanged<String> onToggle;
  final bool is24Hours;
  final bool isClosed;
  final String? businessStart;
  final String? businessEnd;

  const _AvailabilityRow({
    required this.dayLabel,
    required this.selectedBlocks,
    required this.onToggle,
    this.is24Hours = false,
    this.isClosed = false,
    this.businessStart,
    this.businessEnd,
  });

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
          // 曜日ラベル
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

          // 時間帯トグルチップ
          Expanded(
            child: isClosed
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '定休日',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 6,
                    children: TimeBlock.values.map((block) {
                      final isSelected = selectedBlocks.contains(block);
                      final isEnabled = TimeBlock.overlapsBusinessHours(
                        block,
                        is24Hours: is24Hours,
                        isClosed: isClosed,
                        start: businessStart,
                        end: businessEnd,
                      );
                      return ChoiceChip(
                        label: Text(TimeBlock.label(block)),
                        selected: isSelected,
                        onSelected: isEnabled ? (_) => onToggle(block) : null,
                        selectedColor: AppColors.accentPrimary,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: !isEnabled
                              ? Colors.grey
                              : (isSelected ? Colors.white : Colors.black87),
                          fontWeight: FontWeight.w500,
                        ),
                        backgroundColor: isEnabled
                            ? Colors.grey.shade100
                            : Colors.grey.shade200,
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
