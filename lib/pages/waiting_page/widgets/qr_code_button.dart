import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/common_dialogs/base_dialog.dart';
import '../waiting_viewmodel.dart';

class QRCodeButton extends StatelessWidget {
  final String data;
  const QRCodeButton({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.qr_code, color: Colors.white),
          label: const Text('QRコード', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.white),
          onPressed: () {
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
                            data: data, version: QrVersions.auto, size: 180.0),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon:
                          const Icon(Icons.print_outlined, color: Colors.white),
                      label: const Text('出力',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPrimary,
                          foregroundColor: Colors.white),
                      onPressed: () {
                        context
                            .read<WaitingViewModel>()
                            .generateAndSaveQrPdf(context, data);
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
