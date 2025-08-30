import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class VerificationStatusWidget extends StatelessWidget {
  final String status;

  const VerificationStatusWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final IconData iconData;
    final Color backgroundColor;
    final Color iconColor;
    final String title;
    final String subtitle;

    switch (status) {
      case 'PENDING':
      case 'PENDING_REVIEW':
        iconData = Icons.hourglass_top_rounded;
        backgroundColor = AppColors.pendingBackground;
        iconColor = AppColors.pending;
        title = '審査中';
        subtitle = '提出された情報を確認しています。完了までしばらくお待ちください。';
        break;
      case 'APPROVED':
        iconData = Icons.check_circle_rounded;
        backgroundColor = AppColors.approvedBackground;
        iconColor = AppColors.approved;
        title = '承認済み';
        subtitle = '事業者情報の認証が完了しました。';
        break;
      case 'REJECTED':
        iconData = Icons.error_rounded;
        backgroundColor = AppColors.rejectedBackground;
        iconColor = AppColors.rejected;
        title = '承認が拒否されました';
        subtitle = '登録情報に問題がありました。詳細は管理者からのメッセージを確認してください。';
        break;
      default: // NOT_SUBMITTED 또는 예상치 못한 값
        iconData = Icons.edit_document;
        backgroundColor = AppColors.notSubmittedBackground;
        iconColor = AppColors.notSubmitted;
        title = '事業者情報 未提出';
        subtitle = '事業者情報の認証を進めてください。';
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
                    color: AppColors.textPrimary, // 어두운 텍스트 색상
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary.withOpacity(0.8),
                    height: 1.5, // 줄 간격
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
