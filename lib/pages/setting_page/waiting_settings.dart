import 'package:flutter/material.dart';
import 'widget/setting_section_widgets.dart';
import 'dialogs/max_waiting_dialog.dart';
import 'dialogs/estimated_waiting_dialog.dart';
import '../../models/store_settings.dart';

class WaitingSettings extends StatelessWidget {
  final StoreSettings storeSettings;
  final ValueChanged<StoreSettings> onChanged;
  const WaitingSettings(
      {super.key, required this.storeSettings, required this.onChanged});

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSettingItem(
                  '最大待機人数',
                  '${storeSettings.waitingPolicy.maxWaitingCount}人',
                  null,
                  onTap: () {
                    showMaxWaitingDialog(
                      context,
                      storeSettings.waitingPolicy.maxWaitingCount,
                      onConfirm: (value) {
                        final updated = storeSettings.copyWith(
                          waitingPolicy: storeSettings.waitingPolicy.copyWith(maxWaitingCount: value),
                        );
                        onChanged(updated);
                      },
                    );
                  },
                ),
                buildSettingItem(
                  '想定待機人数',
                  // StoreSettings/WaitingPolicyにestimatedWaitingCountがある前提
                  '${storeSettings.waitingPolicy.estimatedWaitingCount}人',
                  null,
                  onTap: () {
                    // showEstimatedWaitingDialogは仮のダイアログ関数名
                    showEstimatedWaitingDialog(
                      context,
                      storeSettings.waitingPolicy.estimatedWaitingCount ?? 0,
                      onConfirm: (value) {
                        final updated = storeSettings.copyWith(
                          waitingPolicy: storeSettings.waitingPolicy.copyWith(estimatedWaitingCount: value),
                        );
                        onChanged(updated);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
