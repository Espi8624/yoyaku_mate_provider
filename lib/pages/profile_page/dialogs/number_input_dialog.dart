import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

//　数字入力のための共通ダイアログウィジェット
class NumberInputDialog extends StatefulWidget {
  final String title;
  final String labelText;
  final int initialValue;

  const NumberInputDialog({
    super.key,
    required this.title,
    required this.labelText,
    required this.initialValue,
  });

  @override
  State<NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<NumberInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text);
    if (value == null) {
      ToastWidget.show(context, '有効な数字を入力してください', type: ToastType.error);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: widget.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: widget.labelText,
            ),
            onSubmitted: (_) => _submit(),
          ),
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
