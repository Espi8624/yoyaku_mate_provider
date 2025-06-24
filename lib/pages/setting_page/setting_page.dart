import 'package:flutter/material.dart';
import 'operation_settings.dart';
import 'waiting_settings.dart';
import 'system_settings.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  // Tab(text: '売上設定'),
                  // Tab(text: 'メニュー設定'),
                  // Tab(text: '使用者及び権限設定'),
                  Tab(text: 'システム設定'),
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
                    OperationSettings(showBusinessHoursDialog: _showBusinessHoursDialog),
                    const WaitingSettings(),
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
    // 요일별 초기값
    final List<String> days = ['月', '火', '水', '木', '金', '土', '日'];
    Map<String, Map<String, int>> businessHours = {
      for (var day in days)
        day: {'startHour': 9, 'startMinute': 0, 'endHour': 22, 'endMinute': 0},
    };

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            '営業時間設定',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 360),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var day in days) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          // 시작 시
                          Expanded(
                            child: DropdownButton<int>(
                              value: businessHours[day]!['startHour'],
                              items: List.generate(24, (index) => DropdownMenuItem(
                                    value: index,
                                    child: Text('$index時', style: const TextStyle(fontSize: 14, color: Color(0xFF263238))),
                                  )),
                              onChanged: (value) {
                                setDialogState(() {
                                  businessHours[day]!['startHour'] = value!;
                                });
                              },
                              isExpanded: true,
                              underline: Container(height: 1, color: const Color(0xFF263238)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // 시작 분
                          Expanded(
                            child: DropdownButton<int>(
                              value: businessHours[day]!['startMinute'],
                              items: List.generate(4, (index) => DropdownMenuItem(
                                    value: index * 15,
                                    child: Text('${index * 15}分', style: const TextStyle(fontSize: 14, color: Color(0xFF263238))),
                                  )),
                              onChanged: (value) {
                                setDialogState(() {
                                  businessHours[day]!['startMinute'] = value!;
                                });
                              },
                              isExpanded: true,
                              underline: Container(height: 1, color: const Color(0xFF263238)),
                            ),
                          ),
                          const Text(' ~ '),
                          // 종료 시
                          Expanded(
                            child: DropdownButton<int>(
                              value: businessHours[day]!['endHour'],
                              items: List.generate(24, (index) => DropdownMenuItem(
                                    value: index,
                                    child: Text('$index時', style: const TextStyle(fontSize: 14, color: Color(0xFF263238))),
                                  )),
                              onChanged: (value) {
                                setDialogState(() {
                                  businessHours[day]!['endHour'] = value!;
                                });
                              },
                              isExpanded: true,
                              underline: Container(height: 1, color: const Color(0xFF263238)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // 종료 분
                          Expanded(
                            child: DropdownButton<int>(
                              value: businessHours[day]!['endMinute'],
                              items: List.generate(4, (index) => DropdownMenuItem(
                                    value: index * 15,
                                    child: Text('${index * 15}分', style: const TextStyle(fontSize: 14, color: Color(0xFF263238))),
                                  )),
                              onChanged: (value) {
                                setDialogState(() {
                                  businessHours[day]!['endMinute'] = value!;
                                });
                              },
                              isExpanded: true,
                              underline: Container(height: 1, color: const Color(0xFF263238)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Color(0xFF263238))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F61),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // 유효성 검사: 각 요일별로 시작 < 종료인지 확인
                bool isValid = true;
                businessHours.forEach((day, times) {
                  final startHour = times['startHour']!;
                  final startMinute = times['startMinute']!;
                  final endHour = times['endHour']!;
                  final endMinute = times['endMinute']!;
                  if (startHour > endHour || (startHour == endHour && startMinute >= endMinute)) {
                    isValid = false;
                  }
                });
                if (!isValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('閉店時間は開店時間より早くできません。')),
                  );
                  return;
                }
                // 저장 로직 (TODO: 실제 저장 구현)
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('営業時間が設定されました。')),
                );
              },
              child: const Text('確認'),
            ),
          ],
        ),
      ),
    );
  }

  // 섹션 제목 위젯
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF263238),
        ),
      ),
    );
  }

  // 설정 항목 위젯
  Widget _buildSettingItem(String title, String subtitle, Widget? trailing,
      {VoidCallback? onTap}) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: Color(0xFF263238)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  // 섹션 박스 위젯
  Widget _sectionBox({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: _boxDecoration(),
      child: child,
    );
  }

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
