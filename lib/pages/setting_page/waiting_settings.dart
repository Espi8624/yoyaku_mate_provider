import 'package:flutter/material.dart';
import 'setting_section_widgets.dart';

class WaitingSettings extends StatelessWidget {
  const WaitingSettings({super.key});

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
                buildSettingItem('最大待機', '人数・時間制限設定', null, onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          buildSectionTitle('自動化'),
          sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSettingItem('予想時間計算', '回転率基盤設定', null, onTap: () {}),
                buildSettingItem('自動呼出', '呼出タイミング設定', Switch(value: false, onChanged: (value) {})),
                buildSettingItem('待機取消', '未応答時自動取消', Switch(value: false, onChanged: (value) {})),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
