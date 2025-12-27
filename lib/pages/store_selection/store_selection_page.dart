import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/models/store_profile.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen_viewmodel.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/join_store_dialog.dart';
import 'package:yoyaku_mate_provider/constants/staff_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/confirmation_dialog.dart';

import 'package:yoyaku_mate_provider/pages/store_selection/store_selection_viewmodel.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';

class StoreSelectionView extends StatelessWidget {
  const StoreSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StoreSelectionViewModel(
        profileService: context.read<ProviderProfileService>(),
        profileVM: context.read<ProfileScreenViewModel>(),
      ),
      child: const _StoreSelectionContent(),
    );
  }
}

class _StoreSelectionContent extends StatelessWidget {
  const _StoreSelectionContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StoreSelectionViewModel>();
    final stores = vm.stores;
    // userNameを取得する
    final userProfile = context.select<ProfileScreenViewModel, String?>(
        (pVm) => pVm.userProfile?.name);
    final userName = userProfile ?? 'ユーザー';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textSecondary),
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
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          _buildStoreList(context, vm, stores, userName),
          if (vm.isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildStoreList(BuildContext context, StoreSelectionViewModel vm,
      List<StoreProfile> stores, String userName) {
    Future<void> navigateToSignUp() async {
      final role =
          context.read<ProfileScreenViewModel>().userProfile?.role ?? 'manager';
      if (role == 'staff') {
        _showJoinStoreDialog(context, vm);
      } else {
        await context.push('/add-store');
        // Return from AddStorePage -> Refresh List
        if (context.mounted) {
          await vm.refreshStores();
        }
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${userName}様、ようこそ！',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              stores.isEmpty
                  ? 'まだ登録された店舗がありません。\n新しい店舗を登録して始めましょう。'
                  : '管理する店舗を選択してください。',
              style: const TextStyle(
                  fontSize: 16, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 40),
            Expanded(
              flex: 5,
              child: stores.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.storefront_outlined,
                        size: 80,
                        color: AppColors.textSecondary.withOpacity(0.4),
                      ),
                    )
                  : ListView.builder(
                      itemCount: stores.length,
                      itemBuilder: (context, index) {
                        final store = stores[index];

                        return StoreCard(
                          store: store,
                          onTap: () async {
                            if (store.staffStatus == StaffStatus.rejected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('この店舗への参加は拒否されました。')),
                              );
                              return;
                            }

                            final success = await vm.selectStore(store.id);

                            if (success && context.mounted) {
                              // selectStoreが返すstoreをそのままStoreProfileに変換してローカルリスト(myStores)に追加する
                            }
                          },
                        );
                      },
                    ),
            ),
            const Spacer(flex: 1),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('新しい店舗を追加'),
                onPressed: navigateToSignUp,
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showJoinStoreDialog(
      BuildContext context, StoreSelectionViewModel vm) async {
    final storeId = await showJoinStoreDialog(context: context);

    if (storeId == null || storeId.isEmpty) {
      return;
    }

    if (!context.mounted) return;

    final success = await vm.joinStore(storeId);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.successMessage ?? '参加申請を送信しました。')),
      );
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: ${vm.errorMessage}')),
      );
    }
  }
}

class StoreCard extends StatelessWidget {
  final StoreProfile store;
  final VoidCallback onTap;

  const StoreCard({super.key, required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRejected = store.staffStatus == StaffStatus.rejected;
    final isPending = store.staffStatus == StaffStatus.pending;
    final isApproved = store.staffStatus == StaffStatus.approved;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(Icons.storefront,
                  color: isRejected ? Colors.grey : AppColors.accentPrimary,
                  size: 32),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isRejected ? Colors.grey : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.address,
                      style: const TextStyle(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isRejected) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Text(
                          '参加拒否',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (isPending) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Text(
                          '承認待ち',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (isApproved) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text(
                          '承認済み',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    // 管理者向け：店舗の承認ステータス表示 (スタッフステータスがない場合)
                    if (store.staffStatus == null) ...[
                      if (store.verificationStatus == 'PENDING' ||
                          store.verificationStatus == 'PENDING_REVIEW') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Text(
                            '審査中',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (store.verificationStatus == 'APPROVED') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text(
                            '承認済み',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (store.verificationStatus == 'REJECTED') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: const Text(
                            '否認',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (store.verificationStatus == 'NOT_SUBMITTED' ||
                          store.verificationStatus == null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Text(
                            '未提出',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (!isRejected)
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
