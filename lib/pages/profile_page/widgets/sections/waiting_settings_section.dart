import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/common_widgets/custom_snack_bar.dart';
import '../../dialogs/number_input_dialog.dart';
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
          showTrailingIcon: false,
          trailing: Switch(
            value: storeSettings.waitingPolicy.enableMenuSelection,
            onChanged: isReadOnly
                ? null
                : (value) async {
                    final updatedPolicy = storeSettings.waitingPolicy
                        .copyWith(enableMenuSelection: value);
                    await vm.updateStoreSettings(
                        storeSettings.copyWith(waitingPolicy: updatedPolicy));
                  },
          ),
        ),
        ProfileSettingItem(
          title: '最大待機人数',
          subtitle: '${storeSettings.waitingPolicy.maxWaitingCount}人',
          showTrailingIcon: !isReadOnly,
          onTap: isReadOnly
              ? null
              : () => _showNumberInputDialog(
                    context,
                    vm,
                    title: '最大待機人数設定',
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
          CustomSnackBar.show(context,
              message: vm.errorMessage!, status: SnackBarStatus.error);
        } else if (vm.successMessage != null) {
          CustomSnackBar.show(context,
              message: '$titleが$result人に設定されました。', status: SnackBarStatus.info);
          vm.clearSuccessMessage();
        }
      }
    }
  }
}
