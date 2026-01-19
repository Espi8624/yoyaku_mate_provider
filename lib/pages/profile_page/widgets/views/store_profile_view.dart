import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../constants/app_colors.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';
import '../../profile_screen_viewmodel.dart';
import '../dialogs/edit_profile_dialog.dart';
import '../profile_header.dart';
import '../profile_section.dart';
import '../profile_setting_item.dart';
import 'staff_approval_status_view.dart';
import 'store_license_status_view.dart';
import '../sections/operation_settings_section.dart';
import '../sections/waiting_settings_section.dart';

class StoreProfileView extends StatelessWidget {
  final bool isReadOnly;

  const StoreProfileView({
    super.key,
    this.isReadOnly = false,
  });

  Future<void> _showEditDialog(
    BuildContext context, {
    required String title,
    required String fieldKey,
    required String initialValue,
  }) async {
    if (isReadOnly) return;

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
        ToastWidget.show(context, '変更が保存されました', type: ToastType.success);
      }
    }
  }

  Future<void> _handleImageUpload(BuildContext context) async {
    if (isReadOnly) return;

    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final vm = context.read<ProfileScreenViewModel>();
      final success = await vm.uploadStoreLicense(imageFile);

      if (context.mounted) {
        if (success) {
          ToastWidget.show(
            context,
            '正常にアップロードされました。',
            type: ToastType.success,
          );
        } else if (vm.errorMessage != null) {
          ToastWidget.show(
            context,
            vm.errorMessage!,
            type: ToastType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileScreenViewModel>();
    final storeProfile = vm.storeProfile;
    final storeLicense = vm.storeLicense;

    if (storeProfile == null || storeLicense == null) {
      if (vm.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(child: Text("店舗情報がありません。"));
    }

    final bool hasLicenseImage =
        storeLicense.imageUrl != null && storeLicense.imageUrl!.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              ProfileHeader(
                name: storeProfile.name,
                imageUrl: storeProfile.storeImageUrl,
                icon: Icons.store,
                onTapImage: isReadOnly
                    ? null
                    : () {
                        vm.uploadStoreImage();
                      },
                onTapName: isReadOnly
                    ? null
                    : () => _showEditDialog(context,
                        title: '店舗名',
                        fieldKey: 'store_name',
                        initialValue: storeProfile.name),
              ),
              const SizedBox(height: 32),

              // 1. 営業許可証 (License)
              if (!isReadOnly) ...[
                ProfileSection(
                  title: '営業許可証',
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: StoreLicenseStatusWidget(
                          status: storeLicense.verificationStatus),
                    ),
                    if ((storeLicense.verificationStatus != 'APPROVED') &&
                        (storeLicense.verificationStatus !=
                            'PENDING_REVIEW')) ...[
                      if (hasLicenseImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.network(
                            storeLicense.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                height: 200,
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                    child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red, size: 40),
                                    SizedBox(height: 8),
                                    Text("イメージの読み込みに失敗しました。"),
                                  ],
                                )),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.cardBackground),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              "まだ登録されていません。",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (!isReadOnly)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label:
                                Text(hasLicenseImage ? "画像を再アップロード" : "画像を登録"),
                            onPressed: () => _handleImageUpload(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentPrimary,
                              foregroundColor: AppColors.textPrimaryLight,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // 2. 基本情報 (Basic Info)
              ProfileSection(
                title: '基本情報',
                children: [
                  ProfileSettingItem(
                    title: '住所',
                    subtitle: storeProfile.address,
                    showTrailingIcon: !isReadOnly,
                    onTap: isReadOnly
                        ? null
                        : () => _showEditDialog(context,
                            title: '住所',
                            fieldKey: 'address',
                            initialValue: storeProfile.address),
                  ),
                  ProfileSettingItem(
                    title: '電話番号',
                    subtitle: storeProfile.phone_number,
                    showTrailingIcon: !isReadOnly,
                    onTap: isReadOnly
                        ? null
                        : () => _showEditDialog(context,
                            title: '電話番号',
                            fieldKey: 'phone_number',
                            initialValue: storeProfile.phone_number),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. 運営設定 (Operation Settings)
              OperationSettingsSection(isReadOnly: isReadOnly),
              const SizedBox(height: 24),

              // 4. 待機リスト政策 (Waiting List Policy)
              WaitingSettingsSection(isReadOnly: isReadOnly),
              const SizedBox(height: 24),

              // 職員の場合、承認状態を表示
              if (isReadOnly && storeProfile.staffStatus != null)
                ProfileSection(
                  title: 'スタッフ承認状態',
                  children: [
                    StaffApprovalStatusWidget(
                        status: storeProfile.staffStatus!),
                  ],
                ),
              if (isReadOnly && storeProfile.staffStatus != null)
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
                icon: const Icon(Icons.swap_horiz_rounded,
                    color: AppColors.textPrimaryLight),
                label: const Text(
                  '管理店舗を変更',
                  style: TextStyle(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  // 現在の店舗選択を解除
                  final profileVM = Provider.of<ProfileScreenViewModel>(context,
                      listen: false);
                  profileVM.clearStoreSelection();
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  side: const BorderSide(
                      color: AppColors.accentPrimary, width: 1.5),
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
