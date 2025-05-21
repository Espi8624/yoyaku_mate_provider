import 'package:flutter/material.dart';

class WaitingPage extends StatelessWidget {
  const WaitingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding:
            EdgeInsets.only(top: 20, left: 3, right: 10, bottom: 3), // 전체 여백
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좌측: 대기 리스트 (2/3 너비)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WaitingListButtons(),
                  SizedBox(height: 10),
                  Expanded(
                    // 추가: 리스트가 남은 공간을 채우고 스크롤 가능
                    child: WaitingListCard(),
                  ),
                ],
              ),
            ),
            SizedBox(width: 11),
            // 우측: 웨이팅 상태 (1/3 너비)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QRCodeButtons(),
                  SizedBox(height: 10),
                  Expanded(
                    child: WaitingStatusArea(),
                  ),
                  // WaitingStatusCard(),
                  // SizedBox(height: 2),
                  // CurrentWaitingCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 새로운 위젯: 대기 리스트 상단 버튼
class WaitingListButtons extends StatelessWidget {
  const WaitingListButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF263238),
          ),
          child: const Text(
            "新しい待機追加",
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text(
            "待機目録初期化",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class WaitingListCard extends StatelessWidget {
  const WaitingListCard({super.key});

  @override
  Widget build(BuildContext context) {
    // 예시 데이터
    final waitingList = [
      {
        'number': '1',
        'team': '5',
        'name': '9933',
        'time': '03:07',
      },
      {
        'number': '2',
        'team': '2',
        'name': '904',
        'time': '05:17',
      },
      {
        'number': '3',
        'team': '2',
        'name': '904',
        'time': '05:17',
      },
      {
        'number': '4',
        'team': '2',
        'name': '904',
        'time': '05:17',
      },
      {
        'number': '5',
        'team': '2',
        'name': '904',
        'time': '05:17',
      },
      {
        'number': '6',
        'team': '2',
        'name': '904',
        'time': '05:17',
      },
      {
        'number': '7',
        'team': '2',
        'name': '904',
        'time': '05:17',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            "待機中のお客様リスト",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            // shrinkWrap: true,
            // physics: const NeverScrollableScrollPhysics(),
            itemCount: waitingList.length,
            itemBuilder: (context, index) {
              final item = waitingList[index];
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
                                "#${item['number']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFFFF6F61),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Text(
                                "${item['name']}様",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF263238),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Text(
                                "${item['team']}名",
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
                          // 기타 정보(메모 등) 필요시 여기에 추가
                          Text(
                            "待機時間　・・・　${item["time"]}",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // 오른쪽: 버튼(세로 중앙)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
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

// 새로운 위젯: 대기 리스트 상단 버튼
class QRCodeButtons extends StatelessWidget {
  const QRCodeButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF263238),
          ),
          child: const Row(
            children: [
              Icon(Icons.qr_code, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "QRコード",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WaitingStatusArea extends StatelessWidget {
  const WaitingStatusArea({super.key});

  @override
  Widget build(BuildContext context) {
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
          const Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusInfo(label: "今から待機したら", value: "20分"),
              SizedBox(height: 8),
              _StatusInfo(label: "チーム当たり待機時間", value: "10分"),
              SizedBox(height: 8),
              _StatusInfo(label: "現在時間帯回転率", value: "3.0"),
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
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 10),
                Text(
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
                    SizedBox(width: 55),
                    Text(
                      "2",
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6F61),
                      ),
                    ),
                    SizedBox(width: 16), // 숫자와 チーム 사이 간격
                    Text(
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
