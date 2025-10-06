import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/models/store_profile.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen_viewmodel.dart';

class StoreSelectionView extends StatelessWidget {
  const StoreSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileScreenViewModel>();
    final stores = vm.myStores;
    final userName = vm.userProfile?.name ?? 'ユーザー';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildStoreList(context, vm, stores, userName),
    );
  }

  Widget _buildStoreList(BuildContext context, ProfileScreenViewModel vm,
      List<StoreProfile> stores, String userName) {
    void _navigateToSignUp() {
      context.go('/signup?mode=add_store');
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                            print('Store Card \'${store.name}\' Tapped!');

                            // ViewModelのselectStoreメソッドを呼出
                            final success = await vm.selectStore(store.id);

                            // 問題なく成功し、Widgetがまだ画面に存在する場合、
                            // 現在の画面（StoreSelectionView）を閉る
                            if (success && context.mounted) {
                              Navigator.of(context).pop();
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
                onPressed: _navigateToSignUp,
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
}

class StoreCard extends StatelessWidget {
  final StoreProfile store;
  final VoidCallback onTap;

  const StoreCard({super.key, required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.storefront,
                  color: AppColors.accentPrimary, size: 32),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.address,
                      style: const TextStyle(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
