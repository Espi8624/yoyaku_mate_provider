import 'package:flutter/material.dart';
import '../widgets/setting_section.dart';
import '../dialogs/number_input_dialog.dart';
import '../../../models/store_settings.dart';
import '../../../widgets/common_widgets/custom_snack_bar.dart';

// 待機リスト設定タブのUIを構成するウィジェット
class WaitingSettingsTab extends StatelessWidget {
  final StoreSettings storeSettings;
  final ValueChanged<StoreSettings> onChanged;

  const WaitingSettingsTab({
    super.key,
    required this.storeSettings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('待機リスト政策'),
          sectionBox(
            child: Column(
              children: [
                buildSettingItem(
                  title: '最大待機人数',
                  subtitle: '${storeSettings.waitingPolicy.maxWaitingCount}人',
                  onTap: () => _showNumberInputDialog(
                    context,
                    title: '最大待機人数設定',
                    initialValue: storeSettings.waitingPolicy.maxWaitingCount,
                    onConfirm: (value) {
                      final updatedPolicy = storeSettings.waitingPolicy
                          .copyWith(maxWaitingCount: value);
                      onChanged(
                          storeSettings.copyWith(waitingPolicy: updatedPolicy));
                    },
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                buildSettingItem(
                  title: '想定待機人数',
                  subtitle:
                      '${storeSettings.waitingPolicy.estimatedWaitingCount}人',
                  onTap: () => _showNumberInputDialog(
                    context,
                    title: '想定待機人数設定',
                    initialValue:
                        storeSettings.waitingPolicy.estimatedWaitingCount ?? 0,
                    onConfirm: (value) {
                      final updatedPolicy = storeSettings.waitingPolicy
                          .copyWith(estimatedWaitingCount: value);
                      onChanged(
                          storeSettings.copyWith(waitingPolicy: updatedPolicy));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNumberInputDialog(
    BuildContext context, {
    required String title,
    required int initialValue,
    required ValueChanged<int> onConfirm,
  }) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => NumberInputDialog(
          title: title, labelText: '人数', initialValue: initialValue),
    );
    if (result != null) {
      onConfirm(result);
      CustomSnackBar.show(context,
          message: '$titleが$result人に設定されました。', status: SnackBarStatus.info);
    }
  }
}
