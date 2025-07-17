import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';
import 'package:yoyaku_mate_provider/widgets/custom_snack_bar.dart';
import '../utils/profile_utils.dart';

class PersonalProfileTab extends StatefulWidget {
  final ProviderProfileService profileService;
  final String userId;
  final VoidCallback? onProfileChanged;
  const PersonalProfileTab({super.key, required this.profileService, required this.userId, this.onProfileChanged});

  @override
  _PersonalProfileTabState createState() => _PersonalProfileTabState();
}

class _PersonalProfileTabState extends State<PersonalProfileTab> {
  Map<String, dynamic>? personalProfile;
  bool isLoading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final data = await widget.profileService.fetchUserProfile(widget.userId);
      if (!mounted) return;
      // 백엔드 응답 필드명을 내부에서 매핑
      setState(() {
        personalProfile = {
          'name': data['data']['user_name'] ?? '',
          'role': data['data']['role'] ?? '',
          'email': data['data']['email'] ?? '',
          'phone': data['data']['phone'] ?? '',
          'avatar': null, // 필요시 data['Avatar'] 등으로 확장
        };
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMsg = 'プロフィール情報の読み込みに失敗しました。';
        isLoading = false;
      });
    }
  }

  Future<void> _updateProfileField(String key, String value) async {
    if (personalProfile == null) return;
    if (!mounted) return;
    setState(() { isLoading = true; });
    try {
      await widget.profileService.updateUserProfile(widget.userId, {key: value});
      await _loadProfile();
      if (widget.onProfileChanged != null) widget.onProfileChanged!();
    } catch (e) {
      if (!mounted) return;
      setState(() { isLoading = false; });
      CustomSnackBar.show(
        context,
        message: 'プロフィールの更新に失敗しました: $e',
        status: SnackBarStatus.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMsg != null) {
      return Center(child: Text(errorMsg!));
    }
    final profile = personalProfile!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  CustomSnackBar.show(
                    context,
                    message: 'プロフィール画像アップロード機能は準備中です',
                    status: SnackBarStatus.info,
                  );
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profile['avatar'] != null
                      ? NetworkImage(profile['avatar'])
                      : null,
                  child: profile['avatar'] == null
                      ? const Icon(Icons.person, color: Colors.white, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showEditDialog('user_name', 'お名前', profile['name']),
                child: Center(
                  child: IntrinsicWidth(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          profile['name'] ?? '',
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
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  profile['role'] == 'manager' ? '管理者' : '職員',
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
                'E-mail',
                profile['email'] ?? '',
                const Icon(Icons.chevron_right),
                onTap: () => _showEditDialog('email', 'E-mail', profile['email']),
              ),
              ProfileUtils.buildSettingItem(
                'パスワード',
                '********',
                const Icon(Icons.chevron_right),
                onTap: _showPasswordChangeDialog,
              ),
              ProfileUtils.buildSettingItem(
                '電話番号',
                profile['phone'] ?? '',
                const Icon(Icons.chevron_right),
                onTap: () => _showEditDialog('phone', '電話番号', profile['phone']),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditDialog(String key, String title, String? currentValue) async {
    TextEditingController controller = TextEditingController(text: currentValue ?? '');
    await ProfileUtils.showEditDialog(
      context: context,
      title: title,
      controller: controller,
      onSave: (value) {
        _updateProfileField(key, value);
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
        _updateProfileField('password', value);
      },
    );
  }
}
