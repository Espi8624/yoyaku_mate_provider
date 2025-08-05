// pages/waiting_page/widgets/waiting_item_card.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/waiting_list.dart';

class WaitingItemCard extends StatefulWidget {
  final WaitingList item;
  final VoidCallback onAction;

  const WaitingItemCard({
    super.key,
    required this.item,
    required this.onAction,
  });

  @override
  State<WaitingItemCard> createState() => _WaitingItemCardState();
}

class _WaitingItemCardState extends State<WaitingItemCard> {
  Timer? _timer;
  String _waitingTime = "--分 --秒";

  @override
  void initState() {
    super.initState();
    _updateWaitingTime();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateWaitingTime());
  }

  @override
  void didUpdateWidget(covariant WaitingItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.registrationTime != oldWidget.item.registrationTime) {
      _updateWaitingTime();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateWaitingTime() {
    if (!mounted) return;
    final duration = DateTime.now().difference(widget.item.registrationTime);
    setState(() {
      _waitingTime = '${duration.inMinutes}分 ${duration.inSeconds % 60}秒';
    });
  }

  Color _getStatusBorderColor(String status) {
    switch (status) {
      case 'notified':
        return AppColors.accentSecondary;
      case 'cancelled':
        return AppColors.error;
      case 'completed':
        return AppColors.textSecondary;
      default:
        return AppColors.border;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'completed':
      case 'cancelled':
        return AppColors.background.withOpacity(0.5);
      default:
        return AppColors.cardBackground;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'waiting':
        return Icons.notifications_active_rounded;
      case 'notified':
        return Icons.check_circle_outline;
      case 'completed':
      case 'cancelled':
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    // notes が null、空欄ではない場合表示
    // 違う場合'なし'表示
    final notesText =
        (item.notes != null && item.notes!.isNotEmpty) ? item.notes! : 'なし';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusBackgroundColor(item.status),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusBorderColor(item.status),
          width: item.status != 'waiting' ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("#${item.queueNumber}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.accentPrimary)),
                    const SizedBox(width: 15),
                    Text("${item.customerName} 様",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.textPrimary)),
                    const SizedBox(width: 15),
                    Text("${item.partySize}名",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.accentPrimary)),
                  ],
                ),
                const Divider(height: 16, thickness: 0.5),
                Text("待機時間　・・・　$_waitingTime",
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                Text("備考　　　・・・　$notesText",
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: widget.onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(75, 75),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Icon(_getStatusIcon(item.status), size: 30),
          ),
        ],
      ),
    );
  }
}
