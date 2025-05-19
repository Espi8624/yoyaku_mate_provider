import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/widgets/reusable_card.dart';

class ShopStatusPage extends StatelessWidget {
  const ShopStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // appBar: AppBar(
      //   title: const Text('Shop Status Page'),
      // ),
      body: ShopStatusLayout(),
    );
  }
}

class ShopStatusLayout extends StatelessWidget {
  const ShopStatusLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(3), // 전체 여백
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: SeatTableWidget(),
                ),
                SizedBox(width: 2), // 좌우 간격
                Expanded(
                  flex: 1,
                  child: StatusTableWidget(),
                ),
              ],
            ),
            SizedBox(height: 1), // 상단-하단 간격
            Row(
              children: [
                Expanded(child: ReservationStatusWidget()),
                SizedBox(width: 2),
                Expanded(child: NotesWidget()),
                SizedBox(width: 2),
                Expanded(child: StockWidget()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SeatTableWidget extends StatelessWidget {
  const SeatTableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ReusableCard(
      title: "テーブル状況",
      child: GridView.count(
        crossAxisCount: 5,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 1.5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(16, (index) {
          return Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0x40FF6F61),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${index + 1}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 5),
                const Text("入店時間 : 13:00", style: TextStyle(fontSize: 14)),
                const SizedBox(height: 7),
                const Text("過ぎた時間 : 01:09", style: TextStyle(fontSize: 14)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class StatusTableWidget extends StatelessWidget {
  const StatusTableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReusableCard(
      title: "状況報告",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "平均回転率 : 3",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "予約者数 : 0",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "待機時間 : 10分",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "待機客数 : 0",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "空いている時間帯",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ReservationStatusWidget extends StatelessWidget {
  const ReservationStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReusableCard(
      title: "予約状況",
      child: Center(
        child: Text("予約状況", style: TextStyle(fontSize: 16)),
      ),
    );
  }
}

class NotesWidget extends StatelessWidget {
  const NotesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReusableCard(
      title: "引き継ぎ事項",
      child: Center(
        child: Text("引き継ぎ事項", style: TextStyle(fontSize: 16)),
      ),
    );
  }
}

class StockWidget extends StatelessWidget {
  const StockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReusableCard(
      title: "在庫状況",
      child: Center(
        child: Text("在庫状況", style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
