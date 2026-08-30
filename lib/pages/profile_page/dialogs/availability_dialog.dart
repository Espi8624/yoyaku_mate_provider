import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/time_block.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';

// 勤務可能な曜日・時間帯を設定するためのダイアログウィジェット
// 曜日ごとに空リストの場合は「勤務不可」を意味する
class AvailabilityDialog extends StatefulWidget {
  final Map<String, dynamic> initialAvailability;

  const AvailabilityDialog({super.key, required this.initialAvailability});

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
                    return _AvailabilityRow(
                      dayLabel: Weekday.labels[index],
                      selectedBlocks: _availability[day]!,
                      onToggle: (block) => _toggleBlock(day, block),
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

  const _AvailabilityRow({
    required this.dayLabel,
    required this.selectedBlocks,
    required this.onToggle,
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
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: TimeBlock.values.map((block) {
                final isSelected = selectedBlocks.contains(block);
                return ChoiceChip(
                  label: Text(TimeBlock.label(block)),
                  selected: isSelected,
                  onSelected: (_) => onToggle(block),
                  selectedColor: AppColors.accentPrimary,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: Colors.grey.shade100,
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
