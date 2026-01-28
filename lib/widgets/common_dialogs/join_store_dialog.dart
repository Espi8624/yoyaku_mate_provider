import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/base_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/qr_scanner_view.dart';
import '../../constants/app_colors.dart';

Future<String?> showJoinStoreDialog({
  required BuildContext context,
}) async {
  final TextEditingController controller = TextEditingController();

  Future<void> _scanQRCode(
      BuildContext context, TextEditingController controller) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerView()),
    );

    if (result != null && context.mounted) {
      controller.text = result;
    }
  }

  return showDialog<String>(
    context: context,
    builder: (context) {
      return BaseDialog(
        title: '店舗に参加',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '管理者から共有された店舗IDを入力してください。',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '店舗ID',
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.accentPrimary,
                    width: 2,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner,
                      color: AppColors.textSecondary),
                  onPressed: () => _scanQRCode(context, controller),
                  tooltip: 'QRコードをスキャン',
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final storeId = controller.text.trim();
                if (storeId.isNotEmpty) {
                  Navigator.of(context).pop(storeId);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '参加',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
