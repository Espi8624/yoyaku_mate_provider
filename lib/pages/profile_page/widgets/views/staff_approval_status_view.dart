import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/staff_status.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class StaffApprovalStatusWidget extends StatelessWidget {
  final String status;

  const StaffApprovalStatusWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final IconData iconData;
    final Color backgroundColor;
    final Color iconColor;
    final String title;
    final String subtitle;

    switch (status) {
      case StaffStatus.pending:
        iconData = Icons.hourglass_top_rounded;
        backgroundColor = AppColors.pendingBackground;
        iconColor = AppColors.pending;
        title = '承認待ち';
        subtitle = '管理者による承認をお待ちください。';
        break;
      case StaffStatus.approved:
        iconData = Icons.check_circle_rounded;
        backgroundColor = AppColors.approvedBackground;
        iconColor = AppColors.approved;
        title = '承認済み';
        subtitle = 'この店舗のスタッフとして承認されました。';
        break;
      case StaffStatus.rejected:
        iconData = Icons.error_rounded;
        backgroundColor = AppColors.rejectedBackground;
        iconColor = AppColors.rejected;
        title = '承認が拒否されました';
        subtitle = '参加申請が拒否されました。詳細は管理者にお問い合わせください。';
        break;
      default:
        iconData = Icons.info_outline;
        backgroundColor = AppColors.notSubmittedBackground;
        iconColor = AppColors.notSubmitted;
        title = '状態不明';
        subtitle = '承認状態を確認できませんでした。';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
