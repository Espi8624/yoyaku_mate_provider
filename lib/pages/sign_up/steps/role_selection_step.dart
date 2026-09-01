import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/sign_up_providers.dart';

class RoleSelectionStep extends ConsumerWidget {
  final VoidCallback onRoleSelected;

  const RoleSelectionStep({
    super.key,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('アカウント作成',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text('どちらで登録を進めますか？',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        const Spacer(),
        _buildRoleButton(
          context,
          label: '管理者として登録',
          icon: Icons.storefront,
          onPressed: () {
            ref.read(signUpNotifierProvider.notifier).setRole('manager');
            onRoleSelected();
          },
        ),
        const SizedBox(height: 16),
        _buildRoleButton(
          context,
          label: '職員として登録',
          icon: Icons.person_outline,
          onPressed: () {
            ref.read(signUpNotifierProvider.notifier).setRole('staff');
            onRoleSelected();
          },
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 24),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
          enableFeedback: false,
        ),
      ),
    );
  }
}
