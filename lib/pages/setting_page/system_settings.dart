import 'package:flutter/material.dart';
import 'setting_section_widgets.dart';

class SystemSettings extends StatelessWidget {
  const SystemSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('データバックアップ'),
          sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSettingItem('バックアップ周期', '日別・周別設定', null, onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          buildSectionTitle('言語及び地域'),
          sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSettingItem('言語設定', '日本語', null, onTap: () {}),
                buildSettingItem('通貨', 'JPY', null, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
