import 'package:flutter/material.dart';
import 'dart:async';

import 'package:yoyaku_mate_provider/models/waiting_list.dart';
import 'package:yoyaku_mate_provider/services/waiting_service.dart';
import 'package:yoyaku_mate_provider/widgets/custom_snack_bar.dart';

class WaitingListCard extends StatefulWidget {
  final List<WaitingList> waitingList;
  final VoidCallback onRefresh;

  const WaitingListCard(
      {required this.waitingList, required this.onRefresh, super.key});

  @override
  State<WaitingListCard> createState() => _WaitingListCardState();
}

class _WaitingListCardState extends State<WaitingListCard> {
  Timer? _timer;
  final Map<String, String> _waitingTimes = {};

  @override
  void initState() {
    super.initState();
    _updateWaitingTimes();
    // 1초마다 대기 시간 업데이트
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateWaitingTimes();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(WaitingListCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 위젯이 업데이트될 때(새로운 데이터가 들어올 때) 대기 시간도 업데이트
    _updateWaitingTimes();
  }

  void _updateWaitingTimes() {
    if (!mounted) return;

    setState(() {
      for (var item in widget.waitingList) {
        _waitingTimes[item.waitingId] =
            _calculateWaitingTime(item.registrationTime);
      }
    });
  }

  void _showNotificationDialog(BuildContext context, WaitingList item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '呼出',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF263238)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('予約番号: ${item.waitingId}'),
              Row(
                children: [
                  Text(
                    item.customerName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    '様を呼出します。',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('最後に詳細をご確認ください。', style: TextStyle(fontSize: 16)),
              Text(
                '${item.partySize}名',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${item.notes}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await WaitingService().updateWaitingStatus(
                      storeId: item.storeId,
                      waitingId: item.waitingId,
                      status: 'notified',
                    );
                    if (mounted) {
                      CustomSnackBar.show(
                        context,
                        message: 'お客様を呼び出しました',
                        status: SnackBarStatus.success,
                      );
                      Navigator.of(context).pop();
                      widget.onRefresh(); // 리스트 새로고침
                    }
                  } catch (e) {
                    if (mounted) {
                      CustomSnackBar.show(
                        context,
                        message: 'エラーが発生しました: $e',
                        status: SnackBarStatus.error,
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6F61),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('呼出'),
              ),
            ),
          ],
        );
      },
    );
  }

  String _calculateWaitingTime(DateTime registrationTime) {
    final currentTime = DateTime.now();
    final duration = currentTime.difference(registrationTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes分 $seconds秒';
  }

  // 상태에 따른 테두리 색상을 반환하는 함수
  Color _getStatusBorderColor(String status) {
    switch (status) {
      case 'notified':
        return const Color(0xFFFFD700); // 노란색
      case 'cancelled':
        return const Color(0xFFFF6B6B); // 빨간색
      case 'completed':
        return const Color(0xFF9E9E9E); // 회색
      default:
        return const Color(0xFFE0E0E0); // 기본 회색
    }
  }

  // 상태별 배경색 반환
  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF9E9E9E); // 회색
      case 'cancelled':
        return const Color(0xFF9E9E9E); // 연한 빨간색
      default:
        return Colors.white;
    }
  }

  // 상태별 아이콘 반환
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'waiting':
        return Icons.notifications_active_rounded; // 대기 중
      case 'notified':
        return Icons.check_circle_outline; // 호출됨
      case 'completed':
        return Icons.help_outline; // 완료
      case 'cancelled':
        return Icons.help_outline; // 취소
      default:
        return Icons.help_outline; // 기본값
    }
  }

  // 상태별 다이얼로그 표시 함수
  void _showStatusBasedDialog(BuildContext context, WaitingList item) {
    switch (item.status) {
      case 'waiting':
        _showNotificationDialog(context, item);
        break;
      case 'notified':
        _showEntryConfirmationDialog(context, item);
        break;
      case 'completed':
      case 'cancelled':
        _showInfoDialog(context, item);
        break;
      default:
        _showNotificationDialog(context, item);
    }
  }

  // null 체크 헬퍼 함수
  bool _isNotEmpty(String? value) {
    return value != null && value.isNotEmpty;
  }

  // 타임존을 JST로 변환하는 헬퍼 함수
  DateTime _convertToJST(DateTime utcTime) {
    return utcTime.toUtc().add(const Duration(hours: 9));
  }

  // 시간을 포맷팅하는 헬퍼 함수
  String _formatTime(DateTime time) {
    final jstTime = _convertToJST(time);
    return "${jstTime.hour.toString().padLeft(2, '0')}:${jstTime.minute.toString().padLeft(2, '0')}:${jstTime.second.toString().padLeft(2, '0')}";
  }

  // 정보 확인 다이얼로그 (completed, cancelled 상태용)
  void _showInfoDialog(BuildContext context, WaitingList item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String formattedRegistrationTime = _formatTime(item.registrationTime);
        String? formattedCalledTime =
            item.calledTime != null ? _formatTime(item.calledTime!) : null;
        String? formattedEntryTime =
            item.entryTime != null ? _formatTime(item.entryTime!) : null;

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '情報',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF263238)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('予約番号: ${item.waitingId}'),
              Row(
                children: [
                  Text(
                    item.customerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    ' 様',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${item.partySize}名',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isNotEmpty(item.contact))
                Text(
                  '連絡先: ${item.contact}',
                  style: const TextStyle(fontSize: 16),
                ),
              if (_isNotEmpty(item.notes))
                Text(
                  'メモ: ${item.notes}',
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 8),
              Text(
                '登録時間: $formattedRegistrationTime',
                style: const TextStyle(fontSize: 16),
              ),
              if (formattedCalledTime != null)
                Text(
                  '呼出時間: $formattedCalledTime',
                  style: const TextStyle(fontSize: 16),
                ),
              if (formattedEntryTime != null)
                Text(
                  '入店時間: $formattedEntryTime',
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // 入店確認ダイアログ (notified 状態用)
  void _showEntryConfirmationDialog(BuildContext context, WaitingList item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '入店確認',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF263238)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('予約番号: ${item.waitingId}'),
              Row(
                children: [
                  Text(
                    item.customerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    ' 様',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${item.partySize}名',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isNotEmpty(item.contact))
                Text(
                  '連絡先: ${item.contact}',
                  style: const TextStyle(fontSize: 16),
                ),
              if (_isNotEmpty(item.notes))
                Text(
                  'メモ: ${item.notes}',
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 16),
              const Text(
                '入店処理を行いますか？',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await WaitingService().updateWaitingStatus(
                          storeId: item.storeId,
                          waitingId: item.waitingId,
                          status: 'completed',
                        );
                        if (mounted) {
                          CustomSnackBar.show(
                            context,
                            message: '入店処理が完了しました',
                            status: SnackBarStatus.success,
                          );
                          Navigator.of(context).pop();
                          widget.onRefresh();
                        }
                      } catch (e) {
                        if (mounted) {
                          CustomSnackBar.show(
                            context,
                            message: 'エラーが発生しました: $e', // 하드코딩된 일본어 메시지
                            status: SnackBarStatus.error,
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F61),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('入店完了'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                "待機中のお客様リスト",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'リスト更新',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF263238),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.waitingList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '待機中のお客様がいません。',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: widget.waitingList.length,
                  itemBuilder: (context, index) {
                    final item = widget.waitingList[index];
                    final waitingTime = _waitingTimes[item.waitingId] ??
                        _calculateWaitingTime(item.registrationTime);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusBackgroundColor(item.status),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: _getStatusBorderColor(item.status),
                          width: item.status != 'waiting' ? 2 : 1,
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
                                    Text(
                                      "#${item.queueNumber}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFFFF6F61),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Text(
                                      "${item.customerName} 様",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF263238),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Text(
                                      "${item.partySize}名",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFFFF6F61),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  height: 16,
                                  indent: 0,
                                  endIndent: 16,
                                  thickness: 0.2,
                                  color: Color(0xFF263238),
                                ),
                                Text(
                                  "待機時間　・・・　$waitingTime",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "備考　　　・・・　${item.notes}",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _showStatusBasedDialog(context, item);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF263238),
                                  minimumSize: const Size(75, 75),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Icon(
                                  _getStatusIcon(item.status),
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
