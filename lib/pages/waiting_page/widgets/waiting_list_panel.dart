import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/models/waiting_list.dart';
import 'waiting_item_card.dart';

class WaitingListPanel extends StatelessWidget {
  final List<WaitingList> waitingList;
  final Future<void> Function() onRefresh;
  final Function(WaitingList) onItemAction;
  final double bottomPadding;

  const WaitingListPanel({
    super.key,
    required this.waitingList,
    required this.onRefresh,
    required this.onItemAction,
    this.bottomPadding = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー部分 (desktopではタイトル非表示、mobileも非表示)
        // Empty container or nothing?
        // Since children is empty list now.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [],
          ),
        ),

        const SizedBox(height: 16),
        // 待機がない場合
        Expanded(
          child: waitingList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('待機中のお客様がいません。',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  // 下にスライドして更新
                  onRefresh: onRefresh,
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    itemCount: waitingList.length,
                    itemBuilder: (context, index) {
                      final item = waitingList[index];
                      return WaitingItemCard(
                        item: item,
                        onAction: () => onItemAction(item),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
