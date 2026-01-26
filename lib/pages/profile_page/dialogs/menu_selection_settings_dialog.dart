import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';

class MenuSelectionSettingsResult {
  final bool enableMenuSelection;
  final bool requireOneMenuPerPerson;

  MenuSelectionSettingsResult(
      this.enableMenuSelection, this.requireOneMenuPerPerson);
}

class MenuSelectionSettingsDialog extends StatefulWidget {
  final bool initialEnableMenuSelection;
  final bool initialRequireOneMenuPerPerson;

  const MenuSelectionSettingsDialog({
    super.key,
    required this.initialEnableMenuSelection,
    required this.initialRequireOneMenuPerPerson,
  });

  @override
  State<MenuSelectionSettingsDialog> createState() =>
      _MenuSelectionSettingsDialogState();
}

class _MenuSelectionSettingsDialogState
    extends State<MenuSelectionSettingsDialog> {
  late bool _enableMenuSelection;
  late bool _requireOneMenuPerPerson;

  @override
  void initState() {
    super.initState();
    _enableMenuSelection = widget.initialEnableMenuSelection;
    _requireOneMenuPerPerson = widget.initialRequireOneMenuPerPerson;
  }

  void _submit() {
    Navigator.of(context).pop(MenuSelectionSettingsResult(
      _enableMenuSelection,
      _enableMenuSelection ? _requireOneMenuPerPerson : false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: 'メニュー選択設定',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('待機登録時メニュー選択有効化'),
            value: _enableMenuSelection,
            onChanged: (value) {
              setState(() {
                _enableMenuSelection = value;
                if (!value) {
                  _requireOneMenuPerPerson =
                      false; // Disable dependency if parent is off
                }
              });
            },
            activeColor: AppColors.accentPrimary,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('1人1メニュー制限'),
            subtitle: const Text('人数分以上のメニュー注文を必須にする'),
            value: _requireOneMenuPerPerson,
            onChanged: _enableMenuSelection
                ? (value) {
                    setState(() {
                      _requireOneMenuPerPerson = value;
                    });
                  }
                : null,
            activeColor: AppColors.accentPrimary,
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
