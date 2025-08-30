import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/common_widgets/custom_snack_bar.dart';
import '../../profile_screen_viewmodel.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../profile_header.dart';
import '../profile_section.dart';
import '../profile_setting_item.dart';
import 'verification_status_view.dart';

class StoreProfileView extends StatelessWidget {
  const StoreProfileView({super.key});

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
      final vm = context.read<ProfileScreenViewModel>();
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
    final vm = context.watch<ProfileScreenViewModel>();
    final storeProfile = vm.storeProfile;
    final storeLicense = vm.storeLicense;

    // 데이터가 아직 로드되지 않았거나 없는 경우를 위한 UI 처리
    if (storeProfile == null || storeLicense == null) {
      // ProfileScreen의 메인 로딩 인디케이터가 이미 있으므로, 여기서는
      // 데이터가 없는 경우의 메시지를 보여주거나 빈 컨테이너를 반환할 수 있습니다.
      return const Center(child: Text("店舗情報がありません。"));
    }

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
          title: '店舗認証状態',
          children: [
            // 새로 만든 위젯에 ViewModel의 상태 값을 전달합니다.
            VerificationStatusWidget(
              status: storeLicense.verificationStatus,
            ),
          ],
        ),
      ],
    );
  }
}
