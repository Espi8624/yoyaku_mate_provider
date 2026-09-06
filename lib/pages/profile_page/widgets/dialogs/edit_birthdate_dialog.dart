import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/widgets/birthdate_input_field.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/base_dialog.dart';

/// 生年月日編集用ダイアログ
///
/// サインアップ画面と同じ[BirthdateInputField]を再利用し、
/// "YYYY-MM-DD"形式の文字列をNavigator.popで返す
class EditBirthdateDialog extends StatefulWidget {
  final String initialBirthdate;

  const EditBirthdateDialog({super.key, required this.initialBirthdate});

  @override
  State<EditBirthdateDialog> createState() => _EditBirthdateDialogState();
}

class _EditBirthdateDialogState extends State<EditBirthdateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialBirthdate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: '生年月日の編集',
      width: 400,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BirthdateInputField(controller: _controller),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('確認'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
