import 'package:flutter/material.dart';
import 'dart:async';

import 'package:yoyaku_mate_provider/models/waiting_list.dart';

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
          title: const Text(
            '呼出',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 모달 닫기
                  },
                  style: ButtonStyle(
                    overlayColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.hovered)) {
                          return Colors.grey[200];
                        }
                        return null;
                      },
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.hovered)) {
                          return Colors.grey[600] ?? Colors.grey;
                        }
                        return Colors.grey[400] ?? Colors.grey;
                      },
                    ),
                  ),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // 추가할 로직이 있다면 여기에 작성
                    Navigator.of(context).pop(); // 모달 닫기
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F61),
                  ),
                  child: const Text(
                    '呼出',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE0E0E0)),
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
                                  _showNotificationDialog(context, item);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF263238),
                                  minimumSize: const Size(75, 75),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_rounded,
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
