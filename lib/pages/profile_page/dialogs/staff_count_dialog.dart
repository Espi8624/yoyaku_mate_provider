import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/time_block.dart';
import '../../../models/store_settings.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';

// 曜日別に必要人数・営業時間中の交代回数(何回交代が発生するか)を設定するためのダイアログウィジェット
// (business_hours_dialog.dart の曜日別行レイアウトを踏襲。数値はキーボードで直接入力する)
// シフトの開始時刻は指定しない(自動配置時に営業時間を(交代回数+1)個のブロックに
// 均等分割して割り当てる。柵の杭と区間の関係と同じで、交代がN回ならブロックはN+1個)
class StaffCountDialog extends StatefulWidget {
  final Map<String, DayStaffRequirement> initialRequirements;
  // 定休日(曜日ラベル、例: '月')の一覧。該当曜日の行は淡色表示にする
  final List<String> closedWeekdayLabels;

  const StaffCountDialog({
    super.key,
    required this.initialRequirements,
    this.closedWeekdayLabels = const [],
  });

  @override
  State<StaffCountDialog> createState() => _StaffCountDialogState();
}

class _StaffCountDialogState extends State<StaffCountDialog> {
  final Map<String, TextEditingController> _countControllers = {};
  final Map<String, TextEditingController> _shiftChangeCountControllers = {};

  @override
  void initState() {
    super.initState();
    for (final day in Weekday.values) {
      final requirement = widget.initialRequirements[day];
      _countControllers[day] =
          TextEditingController(text: '${requirement?.count ?? 0}');
      _shiftChangeCountControllers[day] =
          TextEditingController(text: '${requirement?.shiftChangeCount ?? 0}');
    }
  }

  @override
  void dispose() {
    for (final c in _countControllers.values) {
      c.dispose();
    }
    for (final c in _shiftChangeCountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final result = {
      for (final day in Weekday.values)
        day: DayStaffRequirement(
          count: int.tryParse(_countControllers[day]!.text) ?? 0,
          shiftChangeCount:
              int.tryParse(_shiftChangeCountControllers[day]!.text) ?? 0,
        ),
    };
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const desktopMaxWidth = 420.0;
    final dialogWidth = (screenWidth * 0.9 < desktopMaxWidth)
        ? screenWidth * 0.9
        : desktopMaxWidth;

    return BaseDialog(
      title: '必要人員設定',
      width: dialogWidth,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '曜日ごとに必要な人数と、営業時間中に何回交代が発生するか(交代回数)を'
            '入力してください。営業時間を(交代回数+1)個の時間帯に均等分割し、'
            '各時間帯に必要人数を自動的に割り当てます。',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const _HeaderRow(),
          for (int i = 0; i < Weekday.values.length; i++)
            _StaffCountRow(
              dayLabel: Weekday.labels[i],
              countController: _countControllers[Weekday.values[i]]!,
              shiftChangeCountController:
                  _shiftChangeCountControllers[Weekday.values[i]]!,
              isClosed: widget.closedWeekdayLabels.contains(Weekday.labels[i]),
            ),
        ],
      ),
      // スクロールしても確認ボタンがダイアログ下部に固定表示されるようfooterで指定
      footer: SizedBox(
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
    );
  }
}

// 表のヘッダー行 ("曜日 | 人数 | 交代回数")
class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11,
      color: AppColors.textTertiary,
      fontWeight: FontWeight.w600,
    );
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 36),
          SizedBox(width: 12),
          Expanded(child: Center(child: Text('人数', style: style))),
          Expanded(child: Center(child: Text('交代回数(回)', style: style))),
        ],
      ),
    );
  }
}

class _StaffCountRow extends StatelessWidget {
  final String dayLabel;
  final TextEditingController countController;
  final TextEditingController shiftChangeCountController;
  // 定休日かどうか(trueの場合、行全体を淡色表示にする)
  final bool isClosed;

  const _StaffCountRow({
    required this.dayLabel,
    required this.countController,
    required this.shiftChangeCountController,
    this.isClosed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isClosed ? 0.4 : 1.0,
      child: IgnorePointer(
        ignoring: isClosed,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
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
                child: Center(
                  child: _NumberField(controller: countController, suffix: '名'),
                ),
              ),
              Expanded(
                child: Center(
                  child: _NumberField(
                      controller: shiftChangeCountController, suffix: '回'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// キーボードで直接入力するコンパクトな数値フィールド
class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;

  const _NumberField({required this.controller, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: Colors.grey.shade50,
          suffixText: suffix,
          suffixStyle: const TextStyle(fontSize: 11, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accentPrimary),
          ),
        ),
      ),
    );
  }
}
