import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> profile = {
    'name': '川崎食堂',
    'address': '川崎市中原区新丸子町1-1',
    'phone': '02-1234-5678',
    'logo': null,
    'businessId': '',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              "プロフィール設定",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ロゴアップロード機能は準備中です。')),
                      );
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profile['logo'] != null
                          ? NetworkImage(profile['logo'])
                          : null,
                      child: profile['logo'] == null
                          ? const Icon(Icons.camera_alt, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showEditDialog('name', '店名'),
                    child: Center(
                      child: IntrinsicWidth(
                        // 텍스트 + 아이콘 묶음을 가운데로 정렬
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              profile['name'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                              ),
                            ),
                            const SizedBox(width: 12), // 아이콘과 텍스트 사이 간격만 적당히
                            Icon(
                              Icons.edit,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 기본 정보 섹션
            _buildSectionTitle('基本情報'),
            _sectionBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingItem(
                    '住所',
                    profile['address'],
                    const Icon(Icons.chevron_right),
                    onTap: () => _showEditDialog('address', '住所'),
                  ),
                  _buildSettingItem(
                    '電話番号',
                    profile['phone'],
                    const Icon(Icons.chevron_right),
                    onTap: () => _showEditDialog('phone', '電話番号'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 사업자 정보 섹션
            _buildSectionTitle('事業者情報'),
            _sectionBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingItem(
                    '事業者登録番号',
                    (profile['businessId'] ?? '').isEmpty
                        ? '未登録'
                        : profile['businessId'],
                    const Icon(Icons.chevron_right),
                    onTap: () => _showEditDialog('businessId', '事業者登録番号'),
                  ),
                ],
              ),
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
            color: Color(0xFF263238)),
      ),
    );
  }

  // 설정 항목 위젯
  Widget _buildSettingItem(String title, String subtitle, Widget? trailing,
      {VoidCallback? onTap}) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(fontSize: 16, color: Color(0xFF263238))),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 13, color: Colors.grey)),
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
            blurRadius: 4,
            offset: const Offset(0, 1)),
      ],
    );
  }

  // 텍스트 편집 다이얼로그
  void _showEditDialog(String key, String title) async {
    TextEditingController controller =
        TextEditingController(text: profile[key]);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238)),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: title,
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF263238)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (controller.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('値を入力してください。')),
                );
                return;
              }
              setState(() {
                profile[key] = controller.text;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('変更事項を保存しました。')),
              );
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }
}
