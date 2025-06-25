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
      title: const Text('最大待機人数設定',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238))),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: Color(0xFF263238))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6F61),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final value = int.tryParse(controller.text) ?? initialValue;
            Navigator.pop(context);
            onConfirm(value);
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(content: Text('最大待機人数が${controller.text}人に設定されました。')),
            // );
            CustomSnackBar.show(
              context,
              message: '最大待機人数が${controller.text}人に設定されました。',
              status: SnackBarStatus.info,
            );
          },
          child: const Text('確認'),
        ),
      ],
    ),
  );
}
