import 'package:flutter/material.dart';
import '../utils/profile_utils.dart';

class StoreProfileTab extends StatefulWidget {
  const StoreProfileTab({super.key});

  @override
  _StoreProfileTabState createState() => _StoreProfileTabState();
}

class _StoreProfileTabState extends State<StoreProfileTab> {
  // 가게 프로필 정보
  Map<String, dynamic> storeProfile = {
    'name': '川崎食堂',
    'address': '川崎市中原区新丸子町1-1',
    'phone': '02-1234-5678',
    'logo': null,
    'businessId': '',
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
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
                  backgroundImage: storeProfile['logo'] != null
                      ? NetworkImage(storeProfile['logo'])
                      : null,
                  child: storeProfile['logo'] == null
                      ? const Icon(Icons.store, color: Colors.white, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showEditDialog('name', '店名'),
                child: Center(
                  child: IntrinsicWidth(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          storeProfile['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF263238),
                          ),
                        ),
                        const SizedBox(width: 12),
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

        ProfileUtils.buildSectionTitle('基本情報'),
        ProfileUtils.sectionBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileUtils.buildSettingItem(
                '住所',
                storeProfile['address'],
                const Icon(Icons.chevron_right),
                onTap: () => _showEditDialog('address', '住所'),
              ),
              ProfileUtils.buildSettingItem(
                '電話番号',
                storeProfile['phone'],
                const Icon(Icons.chevron_right),
                onTap: () => _showEditDialog('phone', '電話番号'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        ProfileUtils.buildSectionTitle('事業者情報'),
        ProfileUtils.sectionBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileUtils.buildSettingItem(
                '事業者登録番号',
                (storeProfile['businessId'] ?? '').isEmpty
                    ? '未登録'
                    : storeProfile['businessId'],
                const Icon(Icons.chevron_right),
                onTap: () => _showEditDialog('businessId', '事業者登録番号'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditDialog(String key, String title) async {
    TextEditingController controller =
        TextEditingController(text: storeProfile[key]);
    
    await ProfileUtils.showEditDialog(
      context: context,
      title: title,
      controller: controller,
      onSave: (value) {
        setState(() {
          storeProfile[key] = value;
        });
      },
    );
  }
}