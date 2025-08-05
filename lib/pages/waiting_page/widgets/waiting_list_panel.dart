import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/waiting_list.dart';
import 'waiting_item_card.dart';

class WaitingListPanel extends StatelessWidget {
  final List<WaitingList> waitingList;
  final VoidCallback onRefresh;
  final Function(WaitingList) onItemAction;

  const WaitingListPanel({
    super.key,
    required this.waitingList,
    required this.onRefresh,
    required this.onItemAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              const Text("待機中のお客様リスト",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              IconButton(
                onPressed: onRefresh,
                tooltip: 'リスト更新',
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                    backgroundColor: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
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
      ],
    );
  }
}
