import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/constants/privacy_policy.dart';
import 'package:yoyaku_mate_provider/constants/terms_of_service.dart';
import 'package:yoyaku_mate_provider/providers/session_providers.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/base_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/confirmation_dialog.dart';
import '../../../../models/user_profile.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../profile_header.dart';
import '../profile_section.dart';
import '../profile_setting_item.dart';
import 'package:yoyaku_mate_provider/services/session_service.dart';

String _describeError(Object error) {
  if (error is ApiException) return error.message;
  return '予期しないエラーが発生しました: $error';
}

class PersonalProfileView extends ConsumerWidget {
  final UserProfile userProfile;
  const PersonalProfileView({super.key, required this.userProfile});

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    String? fieldKey,
    required String initialValue,
    bool isPassword = false,
    bool isName = false,
  }) async {
    if (!isPassword) {
      final result = await showDialog(
        context: context,
        builder: (_) => EditProfileDialog(
          title: title,
          initialValue: initialValue,
          initialFurigana:
              isName ? userProfile.nameFurigana : null, // Pass Furigana
          isPassword: false,
          isName: isName,
        ),
      );

      if (result != null) {
        try {
          if (result is Map && isName) {
            await ref
                .read(profileActionsProvider.notifier)
                .updateUserProfileFields(Map<String, dynamic>.from(result));
          } else if (result is String && result.isNotEmpty) {
            await ref
                .read(profileActionsProvider.notifier)
                .updateUserProfileField(fieldKey!, result);
          }

          if (!context.mounted) return;
          ToastWidget.show(context, '変更が保存されました', type: ToastType.success);
        } catch (e) {
          if (!context.mounted) return;
          ToastWidget.show(context, _describeError(e), type: ToastType.error);
        }
      }
    }
  }

  void _showPolicyDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => BaseDialog(
        title: title,
        content: Text(
          content,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      ),
    );
  }

  Future<void> _launchInquiryEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@yoyakumate.jp',
      query: 'subject=【Rusui】 お問い合わせ',
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        // フォールバック: クリップボードにコピーするなど、あるいはエラー表示
        if (context.mounted) {
          ToastWidget.show(context, 'メールアプリを開けませんでした。', type: ToastType.error);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ToastWidget.show(context, 'メールアプリの起動に失敗しました。', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appVersion = ref.watch(appInfoProvider).valueOrNull?.version ?? '';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              ProfileHeader(
                name: userProfile.name,
                furigana: userProfile.nameFurigana, // New
                imageUrl: userProfile.userImageUrl,
                onTapImage: () {
                  ref.read(profileActionsProvider.notifier).uploadUserImage();
                },
                onTapName: () => _showEditDialog(context, ref,
                    title: 'お名前',
                    fieldKey: 'name',
                    initialValue: userProfile.name,
                    isName: true),
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
                    subtitle: userProfile.phone_number,
                    onTap: null,
                    showTrailingIcon: false,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ProfileSection(
                title: 'ポリシー情報',
                children: [
                  ProfileSettingItem(
                    title: '利用規約',
                    subtitle: '',
                    onTap: () => _showPolicyDialog(
                      context,
                      TermsOfService.title,
                      TermsOfService.content,
                    ),
                    showTrailingIcon: true,
                  ),
                  ProfileSettingItem(
                    title: 'プライバシーポリシー',
                    subtitle: '',
                    onTap: () => _showPolicyDialog(
                      context,
                      PrivacyPolicy.title,
                      PrivacyPolicy.content,
                    ),
                    showTrailingIcon: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ProfileSection(
                title: 'ヘルプ',
                children: [
                  ProfileSettingItem(
                    title: '問い合わせ',
                    subtitle: 'support@yoyakumate.jp',
                    onTap: () => _launchInquiryEmail(context),
                    showTrailingIcon: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ProfileSection(
                title: 'アプリ情報',
                children: [
                  ProfileSettingItem(
                    title: 'バージョン',
                    subtitle: appVersion,
                    onTap: null,
                    showTrailingIcon: false,
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
                    // - サーバー側の端末セッションも破棄してから認証を切る
                    await SessionService.instance.clear();
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
