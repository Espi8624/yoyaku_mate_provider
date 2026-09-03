import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';
import 'add_unavailable_range_dialog.dart';

// 特定の1曜日の勤務不可時間帯だけを設定するための軽量ダイアログ
// 曜日バッジをタップした際に表示される
class DayAvailabilityDialog extends StatefulWidget {
  final String dayLabel;
  final List<Map<String, dynamic>> initialRanges;
  // その曜日が定休日かどうか(trueの場合、追加操作を不可にする)
  final bool isClosed;

  const DayAvailabilityDialog({
    super.key,
    required this.dayLabel,
    required this.initialRanges,
    this.isClosed = false,
  });

  @override
  State<DayAvailabilityDialog> createState() => _DayAvailabilityDialogState();
}

class _DayAvailabilityDialogState extends State<DayAvailabilityDialog> {
  late List<Map<String, dynamic>> _ranges;

  @override
  void initState() {
    super.initState();
    _ranges = List<Map<String, dynamic>>.from(widget.initialRanges);
  }

  Future<void> _addRange() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AddUnavailableRangeDialog(),
    );
    if (result == null) return;
    setState(() => _ranges.add(result));
  }

  void _removeRange(int index) {
    setState(() => _ranges.removeAt(index));
  }

  void _submit() {
    Navigator.of(context).pop(_ranges);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const desktopMaxWidth = 360.0;
    final dialogWidth = (screenWidth * 0.85 < desktopMaxWidth)
        ? screenWidth * 0.85
        : desktopMaxWidth;

    return BaseDialog(
      title: '${widget.dayLabel}曜日の勤務不可時間',
      width: dialogWidth,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.isClosed
                ? 'この曜日は定休日です。'
                : '働けない時間帯を追加してください。何も追加しない場合は終日勤務可能として扱われます。',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (widget.isClosed)
            const SizedBox.shrink()
          else ...[
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < _ranges.length; i++)
                  _RangeChip(range: _ranges[i], onDelete: () => _removeRange(i)),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16, color: AppColors.accentPrimary),
                  label: const Text('追加'),
                  labelStyle: const TextStyle(color: AppColors.accentPrimary),
                  backgroundColor: AppColors.accentPrimary.withValues(alpha: 0.08),
                  side: BorderSide.none,
                  onPressed: _addRange,
                ),
              ],
            ),
          ],
        ],
      ),
      footer: widget.isClosed
          ? null
          : SizedBox(
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
    );
  }
}

class _RangeChip extends StatelessWidget {
  final Map<String, dynamic> range;
  final VoidCallback onDelete;

  const _RangeChip({required this.range, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final allDay = range['all_day'] == true;
    final label = allDay ? '終日' : '${range['start_time']}-${range['end_time']}';

    return Chip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: allDay ? FontWeight.w600 : FontWeight.normal,
        color: allDay ? AppColors.rejected : AppColors.textPrimary,
      ),
      backgroundColor: allDay ? AppColors.rejectedBackground : Colors.grey.shade100,
      side: BorderSide.none,
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDelete,
    );
  }
}
