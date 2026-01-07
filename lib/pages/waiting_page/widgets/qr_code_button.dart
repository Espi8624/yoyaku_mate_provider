import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/base_dialog.dart';
import 'package:yoyaku_mate_provider/pages/waiting_page/waiting_screen_viewmodel.dart';

class QRCodeButton extends StatelessWidget {
  final String data;
  const QRCodeButton({super.key, required this.data});

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => BaseDialog(
        title: 'QRコード',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 180.0,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '※ QRコードは毎日変更されます。\n毎日新しく印刷して掲示してください。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.print_outlined, color: Colors.white),
              label: const Text('出力', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                context
                    .read<WaitingScreenViewModel>()
                    .generateAndSaveQrPdf(context, data);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // break point設定
    const double mobileBreakpoint = 700;
    final bool isMobile = MediaQuery.of(context).size.width < mobileBreakpoint;

    // mobile UI
    if (isMobile) {
      return IconButton(
        icon: const Icon(Icons.qr_code_2_rounded),
        tooltip: 'QRコード表示',
        onPressed: () => _showQrDialog(context),
      );
    }
    // desktop UI
    else {
      return Tooltip(
        message: 'QRコード',
        child: ElevatedButton(
          onPressed: () => _showQrDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            minimumSize: Size.zero,
          ),
          child: const Icon(Icons.qr_code_rounded, color: Colors.white),
        ),
      );
    }
  }
}
