import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/confirmation_dialog.dart';
import '../../../../models/user_profile.dart';
import '../../../../widgets/common_widgets/custom_snack_bar.dart';
import '../../profile_screen_viewmodel.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../profile_header.dart';
import '../profile_section.dart';
import '../profile_setting_item.dart';

class PersonalProfileView extends StatelessWidget {
  final UserProfile userProfile;
  const PersonalProfileView({super.key, required this.userProfile});

  Future<void> _showEditDialog(
    BuildContext context, {
    required String title,
    String? fieldKey,
    required String initialValue,
    bool isPassword = false,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => EditProfileDialog(
        title: title,
        initialValue: initialValue,
        isPassword: isPassword,
      ),
    );

    if (!isPassword) {
      final newValue = await showDialog<String>(
        context: context,
        builder: (_) => EditProfileDialog(
          title: title,
          initialValue: initialValue,
          isPassword: false,
        ),
      );

      if (newValue != null && newValue.isNotEmpty) {
        final vm = context.read<ProfileScreenViewModel>();
        final success = await vm.updateProfileField(
            userFieldKey: fieldKey!, value: newValue);
        if (success && context.mounted) {
          CustomSnackBar.show(context,
              message: '変更が保存されました', status: SnackBarStatus.success);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ProfileScreenViewModel>();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              ProfileHeader(
                name: userProfile.name,
                imageUrl: userProfile.userImageUrl,
                onTapImage: () {
                  vm.uploadUserImage();
                },
                onTapName: () => _showEditDialog(context,
                    title: 'お名前',
                    fieldKey: 'user_name',
                    initialValue: userProfile.name),
                subtitle: userProfile.role == 'manager' ? '管理者' : '職員',
              ),
              const SizedBox(height: 32),
              ProfileSection(
                title: '基本情報',
                children: [
                  ProfileSettingItem(
                    title: 'E-mail',
                    subtitle: userProfile.email,
                    onTap: null,
                    showTrailingIcon: false,
                  ),
                  ProfileSettingItem(
                    title: 'パスワード',
                    subtitle: '********',
                    onTap: () {
                      // isPasswordフラグと同時にEditProfileDialogを直接呼出
                      showDialog(
                        context: context,
                        builder: (_) => const EditProfileDialog(
                          title: 'パスワード変更',
                          initialValue: '',
                          isPassword: true,
                        ),
                      );
                    },
                  ),
                  ProfileSettingItem(
                    title: '電話番号',
                    subtitle: userProfile.phone,
                    onTap: () => _showEditDialog(context,
                        title: '電話番号',
                        fieldKey: 'phone',
                        initialValue: userProfile.phone),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded,
                    color: AppColors.textPrimaryLight),
                label: const Text(
                  'ログアウト',
                  style: TextStyle(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final confirmed = await showConfirmationDialog(
                    context: context,
                    title: 'ログアウト',
                    content: '本当にログアウトしますか？',
                    confirmText: 'はい。',
                  );
                  if (confirmed == true) {
                    await FirebaseAuth.instance.signOut();
                  }
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
