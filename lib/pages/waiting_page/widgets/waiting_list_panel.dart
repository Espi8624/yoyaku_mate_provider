import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
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
    // mobileか確認
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              const Text("待機中のお客様リスト",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

              // desktopレイアウト時のみ更新ボタンを表示
              if (!isMobile) ...[
                const SizedBox(width: 16),
                IconButton(
                  onPressed: onRefresh,
                  tooltip: 'リスト更新',
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  style: IconButton.styleFrom(
                      backgroundColor: AppColors.textPrimary),
                ),
              ]
            ],
          ),
        ),
        const SizedBox(height: 8),
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
