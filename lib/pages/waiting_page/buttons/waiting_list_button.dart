import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/pages/waiting_page/modals/add_waiting_dialog.dart';
import 'package:yoyaku_mate_provider/services/waiting_service.dart';

class WaitingListButtons extends StatelessWidget {
  final VoidCallback onRefresh; // 새로고침 콜백 추가

  const WaitingListButtons({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AddWaitingDialog(
                onAddSuccess: onRefresh, // 새로고침 콜백 전달
              ),
            );
          },
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
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  '待機目録初期化',
                  style: TextStyle(
                      color: Color(0xFF263238), fontWeight: FontWeight.bold),
                ),
                content: const Text('現在の待機目録を全て初期化しますか？\nこの操作は取り消しできません。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
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
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      try {
                        final waitingService = WaitingService();
                        await waitingService.clearWaitingList(); // 비동기 작업 완료 대기

                        // UI 업데이트 전에 context가 유효한지 확인
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('待機目録を初期化しました。'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          onRefresh(); // 초기화 후 새로고침
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('待機目録の初期化に失敗しました。'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('初期化'),
                  ),
                ],
              ),
            );
          },
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
