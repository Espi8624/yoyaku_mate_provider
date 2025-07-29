import 'package:flutter/material.dart';
import 'operation_settings.dart';
import 'waiting_settings.dart';
import 'system_settings.dart';
import 'dialogs/business_hours_dialog.dart';
import '../../models/store_settings.dart';
import '../../services/store_settings_service.dart';
import '../../widgets/custom_snack_bar.dart';

class SettingPage extends StatefulWidget {
  final String storeId;
  const SettingPage({super.key, required this.storeId});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StoreSettings? _storeSettings;
  final _service = StoreSettingsService(baseUrl: 'http://localhost:8080'); // 基盤 URL を指定

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final settings = await _service.fetchStoreSettings(widget.storeId);
      setState(() {
        _storeSettings = settings;
      });
    } catch (e) {
      CustomSnackBar.show(
        context,
        message: '設定情報を呼出できませんでした: $e',
        status: SnackBarStatus.error,
      );
    }
  }

  Future<void> _saveSettings(StoreSettings updated) async {
    try {
      await _service.updateStoreSettings(updated);
      setState(() {
        _storeSettings = updated;
      });
      // CustomSnackBar.show(
      //   context,
      //   message: '設定情報を保存しました',
      //   status: SnackBarStatus.success,
      // );
    } catch (e) {
      CustomSnackBar.show(
        context,
        message: '設定情報を保存できませんでした: $e',
        status: SnackBarStatus.error,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_storeSettings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      // backgroundColor: const Color(0xFFF5F5F5),
      body: Container(
        padding:
            const EdgeInsets.only(left: 24, top: 24, right: 24, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            const Text(
              "設定",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 24),
            // タブバー
            Container(
              decoration: _boxDecoration(),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFF263238),
                unselectedLabelColor: const Color(0xFF263238).withOpacity(0.6),
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: Color(0xFF263238),
                    width: 2.0,
                  ),
                  insets: EdgeInsets.symmetric(horizontal: 16.0),
                ),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                padding: const EdgeInsets.all(4),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '運営設定'),
                  Tab(text: '待機リスト設定'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // タブ内容
            Expanded(
              child: ClipRRect(
                child: IndexedStack(
                  index: _tabController.index,
                  children: [
                    OperationSettings(
                      storeSettings: _storeSettings!,
                      onChanged: _saveSettings,
                      showBusinessHoursDialog: _showBusinessHoursDialog,
                    ),
                    WaitingSettings(
                      storeSettings: _storeSettings!,
                      onChanged: _saveSettings,
                    ),
                    const SystemSettings(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBusinessHoursDialog() async {
    // DBで実際の営業時間使用
    final days = ['月', '火', '水', '木', '金', '土', '日'];
    // storeSettings の operatingHours を「時間/分」形態に変換
    final Map<String, Map<String, int>> businessHours = {};
    final dayKeys = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];
    for (int i = 0; i < days.length; i++) {
      final key = dayKeys[i];
      final start = _storeSettings!.operatingHours[key]?['start'] ?? '09:00';
      final end = _storeSettings!.operatingHours[key]?['end'] ?? '22:00';
      final startParts = start.split(':');
      final endParts = end.split(':');
      businessHours[days[i]] = {
        'startHour': int.tryParse(startParts[0]) ?? 9,
        'startMinute': int.tryParse(startParts[1]) ?? 0,
        'endHour': int.tryParse(endParts[0]) ?? 22,
        'endMinute': int.tryParse(endParts[1]) ?? 0,
      };
    }
    await showBusinessHoursDialog(
      context,
      businessHours,
      days,
      onConfirm: () {
        // Dialog で修正された businessHours を StoreSettings に反映
        final newOperatingHours = <String, Map<String, String>>{};
        for (int i = 0; i < days.length; i++) {
          final key = dayKeys[i];
          final bh = businessHours[days[i]]!;
          newOperatingHours[key] = {
            'start':
                '${bh['startHour'].toString().padLeft(2, '0')}:${bh['startMinute'].toString().padLeft(2, '0')}',
            'end':
                '${bh['endHour'].toString().padLeft(2, '0')}:${bh['endMinute'].toString().padLeft(2, '0')}',
          };
        }
        final updated = _storeSettings!.copyWith(operatingHours: newOperatingHours);
        _saveSettings(updated);
      },
    );
  }

  // // ヘッダー Widget
  // Widget _buildSectionTitle(String title) {
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Text(
  //       title,
  //       style: const TextStyle(
  //         fontSize: 20,
  //         fontWeight: FontWeight.bold,
  //         color: Color(0xFF263238),
  //       ),
  //     ),
  //   );
  // }

  // // 設定項目 Widget
  // Widget _buildSettingItem(String title, String subtitle, Widget? trailing,
  //     {VoidCallback? onTap}) {
  //   return ListTile(
  //     title: Text(
  //       title,
  //       style: const TextStyle(fontSize: 16, color: Color(0xFF263238)),
  //     ),
  //     subtitle: Text(
  //       subtitle,
  //       style: const TextStyle(fontSize: 13, color: Colors.grey),
  //     ),
  //     trailing: trailing,
  //     onTap: onTap,
  //     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //   );
  // }

  // // セクションボックス Widget
  // Widget _sectionBox({required Widget child}) {
  //   return Container(
  //     width: double.infinity,
  //     decoration: _boxDecoration(),
  //     child: child,
  //   );
  // }

  // ボックスデザイン
  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}
