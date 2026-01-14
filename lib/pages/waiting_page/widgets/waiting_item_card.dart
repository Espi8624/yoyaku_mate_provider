import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../constants/app_colors.dart';
import '../../../models/waiting_list.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';

class WaitingItemCard extends StatefulWidget {
  final WaitingList item;
  final VoidCallback onAction;
  final VoidCallback? onCancel;
  final String? qrToken;

  const WaitingItemCard({
    super.key,
    required this.item,
    required this.onAction,
    this.onCancel,
    this.qrToken,
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
              // QR Code Button
              if (item.status == 'waiting' || item.status == 'notified') ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showQRDialog(
                      context, item.storeId, item.waitingId, widget.qrToken),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    fixedSize: const Size(65, 65),
                    padding: EdgeInsets.zero,
                    elevation: 1,
                    side: BorderSide(
                        color: AppColors.border.withOpacity(0.5), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Icon(Icons.qr_code, size: 28),
                ),
              ],
              const SizedBox(width: 8),
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

  void _showQRDialog(
      BuildContext context, String storeId, String waitingId, String? qrToken) {
    // TODO: 実際の運用環境に合わせてホストを変更してください (e.g. https://yoyaku-mate.web.app)
    // ローカルテスト用: http://localhost:3000
    // 実機でテストする場合: http://[PC_IP_ADDRESS]:3000
    const String webBaseUrl = "http://localhost:3000";
    String url =
        "$webBaseUrl/waiting-screen-flow?store_id=$storeId&waiting_id=$waitingId";

    if (qrToken != null && qrToken.isNotEmpty) {
      url += "&v_token=$qrToken";
    }

    showDialog(
      context: context,
      builder: (context) => BaseDialog(
        title: "お客様用QRコード",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 180.0,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "お客様のスマホで読み取ると\n待機画面が表示されます",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
          ],
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
