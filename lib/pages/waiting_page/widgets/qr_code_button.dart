import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/base_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 160.0,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                '※ QRコードは毎日変更されます。\n毎日新しく印刷して掲示してください。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                _generateAndSaveQrPdf(context, data);
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: 16),
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
            padding: const EdgeInsets.all(12),
            minimumSize: const Size(48, 48),
          ),
          child: const Icon(Icons.qr_code_rounded, color: Colors.white),
        ),
      );
    }
  }
}

// QRコードをPDF/画像として保存 (モバイルはギャラリー、デスクトップはダウンロードフォルダ)。
// どの共有状態にも依存しない純粋な副作用処理のため、Riverpodには乗せずここに置く。
Future<void> _generateAndSaveQrPdf(BuildContext context, String data) async {
  try {
    // QRコードのイメージデータを生成 (共通)
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: false,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    final qrImage = await qrPainter.toImageData(800.0); // 高解像度で生成
    if (qrImage == null) throw Exception('QRコードイメージ生成失敗');
    final pngBytes = qrImage.buffer.asUint8List();

    // モバイル (Android/iOS) の場合: ギャラリーに保存して開く
    if (Platform.isAndroid || Platform.isIOS) {
      // gal は putImageBytes で保存可能 (権限は内部でハンドリング)
      await Gal.putImageBytes(pngBytes, name: "yoyaku_mate_qr");

      if (context.mounted) {
        ToastWidget.show(context, 'QRコードがギャラリーに保存されました', type: ToastType.success);
      }

      // ギャラリーアプリを開く
      await Gal.open();
      return;
    }

    // デスクトップの場合: PDFまたは画像としてダウンロードフォルダに保存
    // 既存のPDFロジックを維持 (印刷用にはPDFが便利)
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(pw.MemoryImage(pngBytes)),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final fileName = 'QRCode_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        if (context.mounted) {
          ToastWidget.show(context, 'PDFがダウンロードフォルダに保存されました',
              type: ToastType.success);
        }
      }
    } else {
      // Webなどのフォールバック (基本ここには来ないはずだが)
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    }
  } catch (e) {
    if (context.mounted) {
      ToastWidget.show(context, '保存処理中にエラーが発生しました: $e', type: ToastType.error);
    }
  }
}
