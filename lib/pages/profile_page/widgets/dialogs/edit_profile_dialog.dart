import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';

class EditProfileDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final bool isPassword;

  const EditProfileDialog({
    super.key,
    required this.title,
    required this.initialValue,
    this.isPassword = false,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
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
    // Dialog では値だけ返却し、実際のロジック処理は ViewModel がするようにする
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    // BaseDialog を使用するか、ここで直接 AlertDialog を構成
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.title,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
      content: TextField(
        controller: _controller,
        obscureText: widget.isPassword,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.title,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _submit,
            child: const Text('確認'),
          ),
        ),
      ],
    );
  }
}
