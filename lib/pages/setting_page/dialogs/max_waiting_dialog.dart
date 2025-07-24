import 'package:flutter/material.dart';
import '../../../widgets/custom_snack_bar.dart';

Future<void> showMaxWaitingDialog(BuildContext context, int initialValue,
    {required void Function(int) onConfirm}) async {
  final TextEditingController controller =
      TextEditingController(text: initialValue.toString());
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('最大待機人数設定',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238))),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF263238)),
            onPressed: () => Navigator.pop(context),
            splashRadius: 20,
            tooltip: '閉じる',
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('最大待機人数を入力してください',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例: 10',
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F61),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              final value = int.tryParse(controller.text) ?? initialValue;
              Navigator.pop(context);
              onConfirm(value);
              CustomSnackBar.show(
                context,
                message: '最大待機人数が${controller.text}人に設定されました。',
                status: SnackBarStatus.info,
              );
            },
            child: const Text('確認'),
          ),
        ),
      ],
    ),
  );
}
