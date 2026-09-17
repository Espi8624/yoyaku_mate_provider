import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';
import '../../../../services/translation_service.dart';
import '../../../../widgets/common_dialogs/base_dialog.dart';

class CategoryFormDialog extends StatefulWidget {
  final String? initialValue;
  final List<String> existingCategories;
  final Map<String, String> initialTranslations;
  // 店舗の「多言語対応」設定で有効化されている翻訳対象言語(日本語は除く)
  final List<String> activeLanguages;

  const CategoryFormDialog({
    super.key,
    this.initialValue,
    required this.existingCategories,
    this.initialTranslations = const {},
    this.activeLanguages = TranslationService.defaultLanguages,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isLoading = false;
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _controller.text.trim();
    setState(() => _isLoading = true);

    // カテゴリー名が変わった場合のみ再翻訳する。
    // その際、既存の翻訳は全言語ぶん破棄する — 無効化中の言語の訳を残すと、
    // 再度有効化したときに「翻訳済み」と判定されて古い名前の訳が残ってしまう
    // (＝保存されている翻訳は常に現在の原文のもの、という前提を保つ)
    final isRenamed = name != widget.initialValue;
    final translations = isRenamed
        ? <String, String>{}
        : Map<String, String>.from(widget.initialTranslations);
    if (isRenamed && widget.activeLanguages.isNotEmpty) {
      try {
        final result = await TranslationService().translateToMultipleLanguages(
          {'c_0': name},
          widget.activeLanguages,
        );
        result.forEach((lang, transMap) {
          final translated = transMap['c_0'];
          if (translated != null) translations[lang] = translated;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('カテゴリーの翻訳に失敗しました: $e')),
          );
        }
      }
    }

    if (!mounted) return;
    Navigator.of(context)
        .pop({'name': name, 'translations': translations});
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: _isEditing ? 'カテゴリー編集' : 'カテゴリー追加',
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
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
            if (_isEditing)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPrimary,
                          foregroundColor: AppColors.cardBackground,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text("確認"),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 0)),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop('DELETE_ACTION'),
                      child: const Text(
                        "削除",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: AppColors.cardBackground,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text("確認"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
