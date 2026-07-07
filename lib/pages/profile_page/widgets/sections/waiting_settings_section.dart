import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';
import '../../../../models/store_settings.dart';
import '../../dialogs/number_input_dialog.dart';
import '../../dialogs/menu_selection_settings_dialog.dart';
import '../../profile_screen_viewmodel.dart';
import '../profile_section.dart';
import '../profile_setting_item.dart';

class WaitingSettingsSection extends StatelessWidget {
  final bool isReadOnly;

  const WaitingSettingsSection({
    super.key,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileScreenViewModel>();
    final storeSettings = vm.storeSettings;

    if (storeSettings == null) {
      return const SizedBox();
    }

    return ProfileSection(
      title: '待機リスト政策',
      children: [
        ProfileSettingItem(
          title: '待機登録時メニュー選択有効化',
          subtitle:
              storeSettings.waitingPolicy.enableMenuSelection ? 'On' : 'Off',
          showTrailingIcon: !isReadOnly,
          onTap: isReadOnly
              ? null
              : () =>
                  _showMenuSelectionSettingsDialog(context, vm, storeSettings),
        ),
        ProfileSettingItem(
          title: '最大受付可能人数',
          subtitle: '${storeSettings.waitingPolicy.maxWaitingCount}人',
          showTrailingIcon: !isReadOnly,
          onTap: isReadOnly
              ? null
              : () => _showNumberInputDialog(
                    context,
                    vm,
                    title: '最大受付可能人数設定',
                    initialValue: storeSettings.waitingPolicy.maxWaitingCount,
                    onConfirm: (value) async {
                      final updatedPolicy = storeSettings.waitingPolicy
                          .copyWith(maxWaitingCount: value);
                      await vm.updateStoreSettings(
                        storeSettings.copyWith(waitingPolicy: updatedPolicy),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Future<void> _showMenuSelectionSettingsDialog(
    BuildContext context,
    ProfileScreenViewModel vm,
    StoreSettings storeSettings,
  ) async {
    final result = await showDialog<MenuSelectionSettingsResult>(
      context: context,
      builder: (_) => MenuSelectionSettingsDialog(
        initialEnableMenuSelection:
            storeSettings.waitingPolicy.enableMenuSelection,
        initialRequireOneMenuPerPerson:
            storeSettings.waitingPolicy.requireOneMenuPerPerson,
      ),
    );

    if (result != null) {
      final updatedPolicy = storeSettings.waitingPolicy.copyWith(
        enableMenuSelection: result.enableMenuSelection,
        requireOneMenuPerPerson: result.requireOneMenuPerPerson,
      );
      await vm.updateStoreSettings(
        storeSettings.copyWith(waitingPolicy: updatedPolicy),
      );
      if (context.mounted) {
        ToastWidget.show(context, 'メニュー選択設定を更新しました', type: ToastType.info);
      }
    }
  }

  Future<void> _showNumberInputDialog(
    BuildContext context,
    ProfileScreenViewModel vm, {
    required String title,
    required int initialValue,
    required Future<void> Function(int) onConfirm,
  }) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => NumberInputDialog(
          title: title, labelText: '人数', initialValue: initialValue),
    );
    if (result != null) {
      await onConfirm(result);
      if (context.mounted) {
        if (vm.errorMessage != null) {
          ToastWidget.show(context, vm.errorMessage!, type: ToastType.error);
        } else if (vm.successMessage != null) {
          ToastWidget.show(context, '$titleが$result人に設定されました。',
              type: ToastType.info);
          vm.clearSuccessMessage();
        }
      }
    }
  }
}
