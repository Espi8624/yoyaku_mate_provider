import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class StoreLicenseStatusWidget extends StatelessWidget {
  final String status;

  const StoreLicenseStatusWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final IconData iconData;
    final Color backgroundColor;
    final Color iconColor;
    final String title;
    final String subtitle;

    switch (status) {
      case 'PENDING':
        iconData = Icons.hourglass_top_rounded;
        backgroundColor = AppColors.cardBackground;
        iconColor = AppColors.pending;
        title = '承認待ち';
        subtitle = '管理者による営業許可証の確認をお待ちください。';
        break;
      case 'PENDING_REVIEW':
        iconData = Icons.hourglass_top_rounded;
        backgroundColor = AppColors.cardBackground;
        iconColor = AppColors.pending;
        title = '承認待ち';
        subtitle = '管理者による営業許可証の確認をお待ちください。';
        break;
      case 'APPROVED':
        iconData = Icons.check_circle_rounded;
        backgroundColor = AppColors.cardBackground;
        iconColor = AppColors.approved;
        title = '承認済み';
        subtitle = '営業許可証が承認されました。';
        break;
      case 'REJECTED':
        iconData = Icons.error_rounded;
        backgroundColor = AppColors.cardBackground;
        iconColor = AppColors.rejected;
        title = '承認が拒否されました';
        subtitle = '営業許可証が拒否されました。再度アップロードしてください。';
        break;
      case 'NOT_SUBMITTED':
        iconData = Icons.upload_file;
        backgroundColor = AppColors.cardBackground;
        iconColor = AppColors.notSubmitted;
        title = '未提出';
        subtitle = '営業許可証をアップロードしてください。';
        break;
      default:
        iconData = Icons.info_outline;
        backgroundColor = AppColors.cardBackground;
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
