import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/widgets/reusable_card.dart';

class WaitingPage extends StatelessWidget {
  const WaitingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: 20, left: 3, right: 10, bottom: 3), // 전체 여백
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좌측: 대기 리스트 (2/3 너비)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WaitingListButtons(), // 카드 밖으로 빼낸 버튼
                  SizedBox(height: 10),
                  WaitingListCard(),
                ],
              ),
            ),
            SizedBox(width: 2),
            // 우측: 웨이팅 상태 (1/3 너비)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QRCodeButtons(),
                  SizedBox(height: 10),
                  WaitingStatusCard(),
                  SizedBox(height: 2),
                  CurrentWaitingCard(),
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
          child: const Text("新しい待機追加", style: TextStyle(color: Colors.white),),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text("待機目録初期化", style: TextStyle(color: Colors.white),),
        ),
      ],
    );
  }
}

class WaitingListCard extends StatelessWidget {
  const WaitingListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ReusableCard(
      title: "お待ちしている顧客リスト", // ReusableCard의 타이틀만 남김
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 테이블 헤더
          const Row(
            children: [
              Expanded(flex: 1, child: Text("番号")),
              Expanded(flex: 2, child: Text("姓名")),
              Expanded(flex: 2, child: Text("待機時間")),
              Expanded(flex: 2, child: Text("予想待機時間")),
              Expanded(flex: 2, child: Text("ステータス")),
              Expanded(flex: 1, child: Text("")),
            ],
          ),
          const Divider(),
          // 리스트
          SizedBox(  // Expanded 대신 SizedBox로 높이 제한
            height: 300,  // 적절한 높이로 조절
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: Text("${index + 1}")),
                      Expanded(flex: 2, child: Text(["三井", "川崎", "山田"][index])),
                      const Expanded(flex: 2, child: Text("30分")),
                      const Expanded(flex: 2, child: Text("20分")),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF263238),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "waiting",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8), // 버튼과 텍스트 사이 간격
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF263238),
                          ),
                          child: const Text("call", style: TextStyle(color: Colors.white),),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
          child: const Text("QRコード", style: TextStyle(color: Colors.white),),
        ),
      ],
    );
  }
}

class WaitingStatusCard extends StatelessWidget {
  const WaitingStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReusableCard(
      title: "現状ウェイティング状況",
      child: Column(
        children: [
          _StatusRow(label: "予想待機時間", value: "20分"),
          SizedBox(height: 8),
          _StatusRow(label: "現在回転率", value: "3"),
          SizedBox(height: 8),
          _StatusRow(label: "現在時間帯離脱者数", value: "3"),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatusRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class CurrentWaitingCard extends StatelessWidget {
  const CurrentWaitingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReusableCard(
      title: "現在ウェイティング",
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
          ),
          Center(
            child: Text(
              "2チーム",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}