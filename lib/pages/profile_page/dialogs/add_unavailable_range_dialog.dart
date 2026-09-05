import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';

String _formatTimeOfDay(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

// 勤務不可時間帯を1件追加するための小さなダイアログ
// ラジオボタンで「終日」/「時間帯」を選び、「時間帯」の場合は開始時刻+終了時刻を指定する
// (終了時刻の隣の「＋1時間」ボタンで60分ずつ増やせる)
// availability_dialog.dart(7日一括編集)・day_availability_dialog.dart(1日編集)の両方から使う共通部品
class AddUnavailableRangeDialog extends HookWidget {
  const AddUnavailableRangeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = useState('all_day'); // 'all_day' または 'range'
    final startTime = useState(const TimeOfDay(hour: 9, minute: 0));
    final endTime = useState(const TimeOfDay(hour: 10, minute: 0));
    final errorText = useState<String?>(null);

    Future<void> pickStartTime() async {
      final picked =
          await showTimePicker(context: context, initialTime: startTime.value);
      if (picked != null) startTime.value = picked;
    }

    void addOneHour() {
      final total = endTime.value.hour * 60 + endTime.value.minute + 60;
      final clamped = total > 24 * 60 ? 24 * 60 : total;
      endTime.value = TimeOfDay(hour: clamped ~/ 60 % 24, minute: clamped % 60);
    }

    void submit() {
      if (mode.value == 'all_day') {
        Navigator.of(context).pop({'all_day': true});
        return;
      }
      final startMinutes = startTime.value.hour * 60 + startTime.value.minute;
      final endMinutes = endTime.value.hour * 60 + endTime.value.minute;
      if (startMinutes >= endMinutes) {
        errorText.value = '終了時刻は開始時刻より後にしてください';
        return;
      }
      Navigator.of(context).pop({
        'all_day': false,
        'start_time': _formatTimeOfDay(startTime.value),
        'end_time': _formatTimeOfDay(endTime.value),
      });
    }

    return BaseDialog(
      title: '勤務不可時間を追加',
      content: RadioGroup<String>(
        groupValue: mode.value,
        onChanged: (v) => mode.value = v ?? mode.value,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('終日'),
              value: 'all_day',
            ),
            const RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('時間帯'),
              value: 'range',
            ),
            if (mode.value == 'range') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: pickStartTime,
                      child: Text('開始 ${_formatTimeOfDay(startTime.value)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '終了 ${_formatTimeOfDay(endTime.value)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: addOneHour,
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: '＋1時間',
                  ),
                ],
              ),
            ],
            if (errorText.value != null) ...[
              const SizedBox(height: 8),
              Text(errorText.value!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: submit,
                child: const Text('追加'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
