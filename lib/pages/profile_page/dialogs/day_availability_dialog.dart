import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/time_block.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';

// 特定の1曜日の勤務可能時間帯だけを設定するための軽量ダイアログ
// 曜日バッジをタップした際に表示される
class DayAvailabilityDialog extends StatefulWidget {
  final String dayLabel;
  final List<String> initialBlocks;

  const DayAvailabilityDialog({
    super.key,
    required this.dayLabel,
    required this.initialBlocks,
  });

  @override
  State<DayAvailabilityDialog> createState() => _DayAvailabilityDialogState();
}

class _DayAvailabilityDialogState extends State<DayAvailabilityDialog> {
  late Set<String> _selectedBlocks;

  @override
  void initState() {
    super.initState();
    _selectedBlocks = widget.initialBlocks.toSet();
  }

  void _toggleBlock(String block) {
    setState(() {
      if (_selectedBlocks.contains(block)) {
        _selectedBlocks.remove(block);
      } else {
        _selectedBlocks.add(block);
      }
    });
  }

  void _submit() {
    Navigator.of(context).pop(_selectedBlocks.toList());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const desktopMaxWidth = 360.0;
    final dialogWidth = (screenWidth * 0.85 < desktopMaxWidth)
        ? screenWidth * 0.85
        : desktopMaxWidth;

    return BaseDialog(
      title: '${widget.dayLabel}曜日の勤務可能時間',
      width: dialogWidth,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '勤務可能な時間帯を選択してください。選択がない場合は勤務不可として扱われます。',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: TimeBlock.values.map((block) {
              final isSelected = _selectedBlocks.contains(block);
              return ChoiceChip(
                label: Text(TimeBlock.label(block)),
                selected: isSelected,
                onSelected: (_) => _toggleBlock(block),
                selectedColor: AppColors.accentPrimary,
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: Colors.grey.shade100,
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                foregroundColor: AppColors.textPrimaryLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
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
