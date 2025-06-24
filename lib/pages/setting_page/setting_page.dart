import 'package:flutter/material.dart';
import 'operation_settings.dart';
import 'waiting_settings.dart';
import 'system_settings.dart';
import 'dialogs/business_hours_dialog.dart';
import '../../models/store_settings.dart';
import '../../services/store_settings_service.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StoreSettings? _storeSettings;
  final _service = StoreSettingsService(baseUrl: 'http://localhost:8080'); // 실제 주소로 변경

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
      final settings = await _service.fetchStoreSettings('store-001');
      setState(() {
        _storeSettings = settings;
      });
    } catch (e) {
      // 에러 처리 (간단히 스낵바)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('설정 정보를 불러오지 못했습니다: $e')),
      );
    }
  }

  Future<void> _saveSettings(StoreSettings updated) async {
    try {
      await _service.updateStoreSettings(updated);
      setState(() {
        _storeSettings = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: Container(
        padding:
            const EdgeInsets.only(left: 24, top: 24, right: 24, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타이틀
            const Text(
              "設定",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 24),
            // 탭 메뉴
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
            // 탭 내용
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
    // DB에서 실제 영업시간 값 사용
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    // storeSettings의 operatingHours를 시간/분 형태로 변환
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
        // 다이얼로그에서 수정된 businessHours를 StoreSettings에 반영
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

  // // 섹션 제목 위젯
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

  // // 설정 항목 위젯
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

  // // 섹션 박스 위젯
  // Widget _sectionBox({required Widget child}) {
  //   return Container(
  //     width: double.infinity,
  //     decoration: _boxDecoration(),
  //     child: child,
  //   );
  // }

  // 박스 데코레이션
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
