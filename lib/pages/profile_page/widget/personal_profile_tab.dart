import 'package:flutter/material.dart';
import '../utils/profile_utils.dart';

class PersonalProfileTab extends StatefulWidget {
  const PersonalProfileTab({super.key});

  @override
  _PersonalProfileTabState createState() => _PersonalProfileTabState();
}

class _PersonalProfileTabState extends State<PersonalProfileTab> {
  // 개인 프로필 정보
  Map<String, dynamic> personalProfile = {
    'name': 'テスト太郎',
    'user_role': 'manager', // 'manager' 또는 'staff'
    'email': 'test@example.com',
    'password': 'password123',
    'phone': '090-1234-5678',
    'avatar': null,
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
                    const SnackBar(content: Text('プロフィール画像アップロード機能は準備中です。')),
                  );
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: personalProfile['avatar'] != null
                      ? NetworkImage(personalProfile['avatar'])
                      : null,
                  child: personalProfile['avatar'] == null
                      ? const Icon(Icons.person, color: Colors.white, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showEditDialog('name', '名前'),
                child: Center(
                  child: IntrinsicWidth(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          personalProfile['name'],
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
              // 권한 표시
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  personalProfile['user_role'] == 'manager' ? '管理者' : '職員',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
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
                'メールアドレス',
                personalProfile['email'],
                const Icon(Icons.chevron_right),
                onTap: () => _showEditDialog('email', 'メールアドレス'),
              ),
              // 비밀번호 변경
              ProfileUtils.buildSettingItem(
                'パスワード',
                '********',
                const Icon(Icons.chevron_right),
                onTap: _showPasswordChangeDialog,
              ),
              ProfileUtils.buildSettingItem(
                '電話番号',
                personalProfile['phone'],
                const Icon(Icons.chevron_right),
                onTap: () => _showEditDialog('phone', '電話番号'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditDialog(String key, String title) async {
    TextEditingController controller =
        TextEditingController(text: personalProfile[key]);

    await ProfileUtils.showEditDialog(
      context: context,
      title: title,
      controller: controller,
      onSave: (value) {
        setState(() {
          personalProfile[key] = value;
        });
      },
    );
  }

  void _showPasswordChangeDialog() async {
    TextEditingController controller = TextEditingController();
    await ProfileUtils.showEditDialog(
      context: context,
      title: 'パスワード変更',
      controller: controller,
      isPassword: true,
      onSave: (value) {
        setState(() {
          personalProfile['password'] = value;
        });
      },
    );
  }
}
