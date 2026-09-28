import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/translation_service.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';

// 多言語対応設定のためのダイアログウィジェット。
// 全言語(日本語含む)を対等なチェックボックスとして扱い、自由にON/OFFできる。
// 選択した言語(日本語を除く)のみがメニュー登録・編集時の自動翻訳API呼び出し
// 対象になる(コスト削減が目的)
class LanguageSettingsDialog extends StatefulWidget {
  final List<String> initialSupportedLanguages;

  const LanguageSettingsDialog({
    super.key,
    required this.initialSupportedLanguages,
  });

  @override
  State<LanguageSettingsDialog> createState() =>
      _LanguageSettingsDialogState();
}

class _LanguageSettingsDialogState extends State<LanguageSettingsDialog> {
  // 選択肢として並べる全言語(基本言語=日本語・英語・韓国語 + 追加言語を対等に列挙)
  static const List<String> _allSelectableLanguages = [
    ...TranslationService.defaultLanguages,
    ...TranslationService.optionalLanguages,
  ];

  // 初期化ボタンで戻す既定の選択状態(日本語・英語・韓国語)
  static const Set<String> _defaultSelection = {
    ...TranslationService.defaultLanguages,
  };

  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSupportedLanguages.toSet();
  }

  void _reset() {
    setState(() => _selected = {..._defaultSelection});
  }

  void _submit() {
    Navigator.of(context).pop(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: '多言語対応',
      width: 480,
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: _reset,
              child: const Text('初期化'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                foregroundColor: AppColors.textPrimaryLight,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _submit,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '選択した言語のみ、メニュー登録・編集時に自動翻訳されます。\n'
            '言語を増やすほど翻訳APIの呼び出し回数が増える点にご注意ください。\n'
            '(初期化すると日本語・英語・韓国語のみが選択されます)',
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 12),
          ..._allSelectableLanguages.map((lang) {
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: Text(TranslationService.languageLabels[lang]!),
              value: _selected.contains(lang),
              activeColor: AppColors.accentPrimary,
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  _selected.add(lang);
                } else {
                  _selected.remove(lang);
                }
              }),
            );
          }),
        ],
      ),
    );
  }
}
