import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/store_profile.dart';
import '../../../../widgets/common_widgets/custom_snack_bar.dart';
import '../../profile_viewmodel.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../profile_header.dart';
import '../profile_section.dart';
import '../profile_setting_item.dart';

class StoreProfileView extends StatelessWidget {
  final StoreProfile storeProfile;
  const StoreProfileView({super.key, required this.storeProfile});

  Future<void> _showEditDialog(
    BuildContext context, {
    required String title,
    required String fieldKey,
    required String initialValue,
  }) async {
    final newValue = await showDialog<String>(
      context: context,
      builder: (_) =>
          EditProfileDialog(title: title, initialValue: initialValue),
    );

    if (newValue != null && newValue.isNotEmpty) {
      final vm = context.read<ProfileViewModel>();
      final success =
          await vm.updateProfileField(storeFieldKey: fieldKey, value: newValue);
      if (success && context.mounted) {
        CustomSnackBar.show(context,
            message: '変更が保存されました', status: SnackBarStatus.success);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        ProfileHeader(
          name: storeProfile.name,
          imageUrl: storeProfile.logoUrl,
          icon: Icons.store,
          onTapImage: () => CustomSnackBar.show(context,
              message: '準備中です', status: SnackBarStatus.info),
          onTapName: () => _showEditDialog(context,
              title: '店舗名',
              fieldKey: 'store_name',
              initialValue: storeProfile.name),
        ),
        const SizedBox(height: 32),
        ProfileSection(
          title: '基本情報',
          children: [
            ProfileSettingItem(
              title: '住所',
              subtitle: storeProfile.address,
              onTap: () => _showEditDialog(context,
                  title: '住所',
                  fieldKey: 'address',
                  initialValue: storeProfile.address),
            ),
            ProfileSettingItem(
              title: '電話番号',
              subtitle: storeProfile.phone,
              onTap: () => _showEditDialog(context,
                  title: '電話番号',
                  fieldKey: 'phone',
                  initialValue: storeProfile.phone),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ProfileSection(
          title: '事業者情報',
          children: [
            ProfileSettingItem(
              title: '事業者登録情報',
              subtitle: storeProfile.bizNumber.isEmpty
                  ? '未登録'
                  : storeProfile.bizNumber,
              onTap: () => _showEditDialog(context,
                  title: '事業者登録番号',
                  fieldKey: 'biz_number',
                  initialValue: storeProfile.bizNumber),
            ),
          ],
        ),
      ],
    );
  }
}
