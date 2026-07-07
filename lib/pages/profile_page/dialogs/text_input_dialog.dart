import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';

class TextInputDialog extends StatefulWidget {
  final String title;
  final String labelText;
  final String initialValue;
  final String? helperText;
  final int maxLines;

  const TextInputDialog({
    super.key,
    required this.title,
    required this.labelText,
    this.initialValue = '',
    this.helperText,
    this.maxLines = 5,
  });

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: widget.title,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.helperText != null) ...[
              Text(
                widget.helperText!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _controller,
              keyboardType: TextInputType.multiline,
              maxLines: widget.maxLines,
              minLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: widget.labelText,
                alignLabelWithHint: true,
              ),
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
      ),
    );
  }
}
