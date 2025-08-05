import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';
import '../../../../widgets/common_dialogs/base_dialog.dart';

class CategoryFormDialog extends StatefulWidget {
  final String? initialValue;
  final List<String> existingCategories;

  const CategoryFormDialog({
    super.key,
    this.initialValue,
    required this.existingCategories,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool get _isEditing => widget.initialValue != null;

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
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: _isEditing ? 'カテゴリー編集' : 'カテゴリー追加',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'カテゴリー名', border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'カテゴリー名を入力してください。';
                }
                final existing = List<String>.from(widget.existingCategories);
                if (_isEditing) existing.remove(widget.initialValue);
                if (existing.contains(value.trim())) {
                  return '同じカテゴリー名が既に存在します。';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: AppColors.cardBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _submit,
                child: const Text("確認"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
