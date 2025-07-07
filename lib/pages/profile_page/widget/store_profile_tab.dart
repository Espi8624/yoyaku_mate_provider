import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/services/provider_profile_service.dart';
import 'package:yoyaku_mate_provider/widgets/custom_snack_bar.dart';
import '../utils/profile_utils.dart';

class StoreProfileTab extends StatefulWidget {
  final ProviderProfileService profileService;
  final String storeId;
  final VoidCallback? onProfileChanged;
  const StoreProfileTab({super.key, required this.profileService, required this.storeId, this.onProfileChanged});

  @override
  _StoreProfileTabState createState() => _StoreProfileTabState();
}

class _StoreProfileTabState extends State<StoreProfileTab> {
  Map<String, dynamic>? storeProfile;
  bool isLoading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final data = await widget.profileService.fetchStoreProfile(widget.storeId);
      setState(() {
        storeProfile = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = '店舗情報の読み込みに失敗しました。';
        isLoading = false;
      });
    }
  }

  Future<void> _updateProfileField(String key, String value) async {
    if (storeProfile == null) return;
    setState(() { isLoading = true; });
    try {
      await widget.profileService.updateStoreProfile(widget.storeId, {key: value});
      await _loadProfile();
      if (widget.onProfileChanged != null) widget.onProfileChanged!();
    } catch (e) {
      setState(() { isLoading = false; });
      CustomSnackBar.show(
        context,
        message: '店舗情報の更新に失敗しました: $e',
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
    final profile = storeProfile!;
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
                    message: 'ロゴアップロード機能は準備中です',
                    status: SnackBarStatus.info,
                  );
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profile['logo'] != null
                      ? NetworkImage(profile['logo'])
                      : null,
                  child: profile['logo'] == null
                      ? const Icon(Icons.store, color: Colors.white, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showEditDialog('store_name', '店舗名', profile['store_name']),
                child: Center(
                  child: IntrinsicWidth(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          profile['store_name'] ?? '',
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
                profile['address'] ?? '',
                const Icon(Icons.chevron_right),
                onTap: () => _showEditDialog('address', '住所', profile['address']),
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
        const SizedBox(height: 24),
        ProfileUtils.buildSectionTitle('事業者情報'),
        ProfileUtils.sectionBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileUtils.buildSettingItem(
                '事業者登録情報',
                (profile['biz_number'] ?? '').isEmpty ? '未登録' : profile['biz_number'],
                const Icon(Icons.chevron_right),
                onTap: () => _showEditDialog('biz_number', '事業者登録番号', profile['biz_number']),
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
}