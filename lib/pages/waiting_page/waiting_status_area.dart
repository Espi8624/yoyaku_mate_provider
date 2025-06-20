import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/models/waiting_list.dart';

class WaitingStatusArea extends StatelessWidget {
  final int waitingCount;
  final List<WaitingList> waitingList;

  const WaitingStatusArea({
    super.key,
    required this.waitingCount,
    required this.waitingList,
  });

  String _formatLastEntryTime() {
    final lastEntry = waitingList
        .where((item) => item.entryTime != null)
        .map((item) => item.entryTime!)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (lastEntry.isEmpty) return "--:--";

    // 오늘 날짜만 고려
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastEntryTime = lastEntry.firstWhere(
      (time) => DateTime(time.year, time.month, time.day).isAtSameMomentAs(today),
      orElse: () => DateTime(0),
    );

    if (lastEntryTime.year == 0) return "--:--";

    // UTC를 JST로 변환
    final jst = lastEntryTime.toUtc().add(const Duration(hours: 9));
    return "${jst.hour.toString().padLeft(2, '0')}:${jst.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final lastEntryTime = _formatLastEntryTime();

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          const Text(
            "現状ウェイティング状況",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 16),
          // 상태 정보
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _StatusInfo(label: "本日混雑予想時間帯", value: "13時"),
              const SizedBox(height: 8),
              _StatusInfo(label: "直前入場時間", value: lastEntryTime),
              const SizedBox(height: 8),
              const _StatusInfo(label: "平均待機時間", value: "10分"),
              const SizedBox(height: 8),
              const _StatusInfo(label: "現在時間帯回転率", value: ""),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "今後追加される予定です",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 현재 웨이팅을 아래로 내리기 위해 Spacer 사용
          const Spacer(),
          // 현재 웨이팅 강조 상자
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF263238),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF263238), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "現在待機チーム",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 55),
                    Text(
                      waitingCount.toString(),
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6F61),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "チーム",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusInfo extends StatelessWidget {
  final String label;
  final String value;
  const _StatusInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6F61),
          ),
        ),
      ],
    );
  }
}
