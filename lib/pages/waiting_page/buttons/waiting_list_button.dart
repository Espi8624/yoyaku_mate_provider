import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/pages/waiting_page/modals/add_waiting_dialog.dart';
import 'package:yoyaku_mate_provider/services/waiting_service.dart';
import 'package:yoyaku_mate_provider/widgets/custom_snack_bar.dart';

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
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "待機目録初期化",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF263238),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon:
                              const Icon(Icons.close, color: Color(0xFF263238)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                content: const Text('現在の待機目録を全て初期化しますか？\nこの操作は取り消しできません。'),
                actionsAlignment: MainAxisAlignment.center, // actions를 가운데 정렬
                actions: [
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      try {
                        final waitingService = WaitingService();
                        await waitingService.clearWaitingList(); // 비동기 작업 완료 대기

                        // UI 업데이트 전에 context가 유효한지 확인
                        if (context.mounted) {
                          CustomSnackBar.show(
                            context,
                            message: '待機目録を初期化しました',
                            status: SnackBarStatus.success,
                          );
                          onRefresh(); // 초기화 후 새로고침
                        }
                      } catch (e) {
                        if (context.mounted) {
                          CustomSnackBar.show(
                            context,
                            message: '待機目録の初期化に失敗しました',
                            status: SnackBarStatus.error,
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
