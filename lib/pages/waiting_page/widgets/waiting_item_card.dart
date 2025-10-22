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
    final minutes = duration.inMinutes > 0 ? duration.inMinutes : 0;
    final seconds = duration.inSeconds > 0 ? duration.inSeconds % 60 : 0;
    setState(() {
      _waitingTime = '${minutes}分 ${seconds}秒';
    });
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

    // ▼▼▼ [수정] 여기가 MenuItemCard의 스타일과 100% 동일하게 수정된 부분입니다. ▼▼▼
    return Card(
      // 1. MenuItemCard와 동일한 margin, color, elevation, shadowColor, shape 적용
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      color: AppColors.cardBackground,
      elevation: 4,
      shadowColor: AppColors.textSecondary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // 2. MenuItemCard와 동일한 테두리 스타일 적용
        side: BorderSide(color: AppColors.border.withOpacity(0.4), width: 1),
      ),
      child: Opacity(
        // 3. 기존의 상태별 기능(완료/취소 시 반투명 처리)은 그대로 유지
        opacity: (item.status == 'completed' || item.status == 'cancelled')
            ? 0.5
            : 1.0,
        child: Padding(
          // 4. MenuItemCard와 동일한 내부 여백(padding) 적용
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- 왼쪽 정보 영역 ---
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
                    if (item.status == 'completed' && item.entryTime != null)
                      // "완료" 상태이고 입장 시간이 있으면, 입장 시간을 표시
                      _buildInfoRow(
                          "入場時間",
                          // 예: 10:55
                          '${item.entryTime!.hour.toString().padLeft(2, '0')}:${item.entryTime!.minute.toString().padLeft(2, '0')}')
                    else
                      // 그 외의 모든 상태에서는 기존의 대기 시간을 표시
                      _buildInfoRow("待機時間", _waitingTime),
                    const SizedBox(height: 4),
                    _buildInfoRow("備考", notesText),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // --- 오른쪽 알림 버튼 영역 ---
              ElevatedButton(
                onPressed:
                    (item.status == 'completed' || item.status == 'cancelled')
                        ? null // 완료/취소 시 버튼 비활성화
                        : widget.onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.white,
                  fixedSize: const Size(80, 80),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // 일관성을 위해 16으로 조정
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

  // [수정] 정보 행(Row)을 만드는 헬퍼 위젯 (더 간결하게)
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60, // 레이블 너비를 고정하여 줄 맞춤
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
