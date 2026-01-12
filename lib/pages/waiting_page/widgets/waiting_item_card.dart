import 'dart:async';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/waiting_list.dart';

class WaitingItemCard extends StatefulWidget {
  final WaitingList item;
  final VoidCallback onAction;
  final VoidCallback? onCancel;

  const WaitingItemCard({
    super.key,
    required this.item,
    required this.onAction,
    this.onCancel,
  });

  @override
  State<WaitingItemCard> createState() => _WaitingItemCardState();
}

class _WaitingItemCardState extends State<WaitingItemCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 1秒ごとに画面を更新して経過時間を最新に保つ
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'waiting':
        return Icons.notifications_active_rounded;
      case 'notified':
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final notesText =
        (item.notes != null && item.notes!.isNotEmpty) ? item.notes! : 'なし';

    final duration = DateTime.now().difference(item.registrationTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final waitTimeStr = '$minutes分 $seconds秒';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      color: AppColors.cardBackground,
      elevation: 4,
      shadowColor: AppColors.textSecondary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withOpacity(0.4), width: 1),
      ),
      child: Opacity(
        opacity: (item.status == 'completed' || item.status == 'cancelled')
            ? 0.5
            : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "#${item.queueNumber} 様   ${item.partySize}名",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (item.status == 'completed')
                      const Text(
                        "入店済み",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      )
                    else if (item.status == 'cancelled')
                      const Text(
                        "待機取消",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      )
                    else ...[
                      _buildInfoRow("待機時間", waitTimeStr),
                      const SizedBox(height: 4),
                      _buildInfoRow("備考", notesText),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: widget.onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.white,
                  fixedSize: const Size(80, 80),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Icon(_getStatusIcon(item.status), size: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
