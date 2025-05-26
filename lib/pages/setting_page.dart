import 'package:flutter/material.dart';

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
    _tabController = TabController(length: 6, vsync: this);
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
                  Tab(text: '売上設定'),
                  Tab(text: 'メニュー設定'),
                  Tab(text: '使用者及び権限設定'),
                  Tab(text: 'システム及び統合設定'),
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
                    _buildOperationSettings(),
                    _buildWaitingSettings(),
                    _buildSalesSettings(),
                    _buildMenuSettings(),
                    _buildUserSettings(),
                    _buildSystemSettings(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 운영 설정 탭
  Widget _buildOperationSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('営業日及び時間'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('営業時間', '平日/週末時間帯設定', null, onTap: _showBusinessHoursDialog),
                _buildSettingItem('休業日', '休業日設定', null, onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('座席'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('テーブル管理', 'テーブル数設定', null,
                    onTap: () {}),
                // _buildSettingItem('予約時間設定', '最大予約時間設定', null, onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('お知らせ'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('お知らせ方式', 'SMS, アッププッシュ, E-mail', null,
                    onTap: () {}),
                _buildSettingItem('お客様お知らせ', '状態変更時お知らせ活性化',
                    Switch(value: false, onChanged: (value) {})),
              ],
            ),
          ),
        ],
      ),
    );
  }

void _showBusinessHoursDialog() async {
  final Map<String, Map<String, int>> businessHours = {
    '平日 (月-金)': {'startHour': 9, 'startMinute': 0, 'endHour': 22, 'endMinute': 0},
    '週末 (土-日)': {'startHour': 10, 'startMinute': 0, 'endHour': 23, 'endMinute': 0},
  };
  String selectedDay = '平日 (月-金)';

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
                // 요일 선택 탭
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: businessHours.keys.map((day) => ChoiceChip(
                        label: Text(day, style: const TextStyle(fontSize: 14, color: Color(0xFF263238))),
                        selected: selectedDay == day,
                        selectedColor: const Color(0xFF263238).withOpacity(0.1),
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              selectedDay = day;
                            });
                          }
                        },
                      )).toList(),
                ),
                const SizedBox(height: 16),
                // 시작 시간 선택
                const Text('開店時間', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        value: businessHours[selectedDay]!['startHour'],
                        items: List.generate(24, (index) => DropdownMenuItem(
                              value: index,
                              child: Text('$index時', style: const TextStyle(fontSize: 14, color: Color(0xFF263238))),
                            )),
                        onChanged: (value) {
                          setDialogState(() {
                            businessHours[selectedDay]!['startHour'] = value!;
                          });
                        },
                        isExpanded: true,
                        underline: Container(height: 1, color: const Color(0xFF263238)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<int>(
                        value: businessHours[selectedDay]!['startMinute'],
                        items: List.generate(4, (index) => DropdownMenuItem(
                              value: index * 15,
                              child: Text('${index * 15}分', style: const TextStyle(fontSize: 14, color: Color(0xFF263238))),
                            )),
                        onChanged: (value) {
                          setDialogState(() {
                            businessHours[selectedDay]!['startMinute'] = value!;
                          });
                        },
                        isExpanded: true,
                        underline: Container(height: 1, color: const Color(0xFF263238)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 종료 시간 선택
                const Text('閉店時間', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        value: businessHours[selectedDay]!['endHour'],
                        items: List.generate(24, (index) => DropdownMenuItem(
                              value: index,
                              child: Text('$index時', style: const TextStyle(fontSize: 14, color: Color(0xFF263238))),
                            )),
                        onChanged: (value) {
                          setDialogState(() {
                            businessHours[selectedDay]!['endHour'] = value!;
                          });
                        },
                        isExpanded: true,
                        underline: Container(height: 1, color: const Color(0xFF263238)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<int>(
                        value: businessHours[selectedDay]!['endMinute'],
                        items: List.generate(4, (index) => DropdownMenuItem(
                              value: index * 15,
                              child: Text('${index * 15}分', style: const TextStyle(fontSize: 14, color: Color(0xFF263238))),
                            )),
                        onChanged: (value) {
                          setDialogState(() {
                            businessHours[selectedDay]!['endMinute'] = value!;
                          });
                        },
                        isExpanded: true,
                        underline: Container(height: 1, color: const Color(0xFF263238)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 미리보기
                Text(
                  '選択された時間: ${businessHours[selectedDay]!['startHour']}:${businessHours[selectedDay]!['startMinute'].toString().padLeft(2, '0')} ~ '
                  '${businessHours[selectedDay]!['endHour']}:${businessHours[selectedDay]!['endMinute'].toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
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
              backgroundColor: const Color(0xFF263238),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              // 유효성 검사
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
              // 저장 로직
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

  // 웨이팅 관리 설정 탭
  Widget _buildWaitingSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('待機リスト政策'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('最大待機', '人数・時間制限設定', null, onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('自動化'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('予想時間計算', '回転率基盤設定', null, onTap: () {}),
                _buildSettingItem('自動呼出', '呼出タイミング設定',
                    Switch(value: false, onChanged: (value) {})),
                _buildSettingItem('待機取消', '未応答時自動取消',
                    Switch(value: false, onChanged: (value) {})),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('顧客コミュニケーション'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('お知らせテンプレート', '入場お知らせメッセージ設定', null, onTap: () {}),
                
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 매상 관리 설정 탭
  Widget _buildSalesSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('売上入力'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('入力方式', '手動, POS連動, 自動', null,
                    onTap: () {}),
                _buildSettingItem('決済手段', '現金, カード, モバイル決済', null,
                    onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('財務設定'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('税金計算', 'VAT 含む/除外', null, onTap: () {}),
                _buildSettingItem('返金/取消', '処理規則設定', null, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 메뉴 관리 설정 탭
  Widget _buildMenuSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('メニュー管理'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('メニューテーマ', 'メニューリストデザイン管理', null, onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('メニュー表示'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('おすすめメニュー', '露出順番設定', null, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 사용자 및 권한 관리 탭
  Widget _buildUserSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('職員アカウント'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('アカウント管理', '職員権限設定', null, onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('顧客データ'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('データ管理', '顧客情報バックアップ及び削除', null,
                    onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('保安'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('2段階認証', '手段選択',
                    Switch(value: false, onChanged: (value) {})),
                _buildSettingItem('接近ログ', '活動記録設定', null, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 시스템 및 통합 설정 탭
  Widget _buildSystemSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('外部システム連動'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('POS 連動', 'POS システム連動', null, onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('データバックアップ'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('バックアップ周期', '日別・周別設定', null, onTap: () {}),
                // _buildSettingItem('저장 위치', '클라우드, 로컬 설정', null, onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('言語及び地域'),
          _sectionBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingItem('言語設定', '日本語', null, onTap: () {}),
                _buildSettingItem('通貨', 'JPY', null, onTap: () {}),
              ],
            ),
          ),
        ],
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
