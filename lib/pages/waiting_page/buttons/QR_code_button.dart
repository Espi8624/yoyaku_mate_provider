import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:yoyaku_mate_provider/widgets/custom_snack_bar.dart';

class QRCodeButton extends StatelessWidget {
  final String data;

  const QRCodeButton({super.key, required this.data});

  Future<void> _generateAndSavePDF(BuildContext context) async {
    try {
      final pdf = pw.Document();

      final qrImage = await QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: false,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ).toImageData(400.0);

      if (qrImage != null) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(
                  pw.MemoryImage(qrImage.buffer.asUint8List()),
                  width: 200,
                  height: 200,
                  fit: pw.BoxFit.contain,
                ),
              );
            },
          ),
        );
      }

      final Uint8List pdfBytes = await pdf.save();
      String fileName = 'QRCode_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final directory = await getDownloadsDirectory();
        if (directory != null) {
          final filePath = '${directory.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(pdfBytes);

          CustomSnackBar.show(
            context,
            message: 'PDFが保存されました。ダウンロードファイルをご確認ください',
            status: SnackBarStatus.success,
          );
        }
      } else {
        try {
          await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
        } catch (e) {
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(pdfBytes);

          CustomSnackBar.show(
            context,
            message: 'PDFが保存されました。ダウンロードファイルをご確認ください',
            status: SnackBarStatus.success,
          );
        }
      }
    } catch (e) {
      CustomSnackBar.show(
        context,
        message: 'PDF生成中にエラーが発生しました: $e',
        status: SnackBarStatus.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: const Color(0xffffffff),
                  title: const Text(
                    'QRコード',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  content: SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: QrImageView(
                        data: data,
                        version: QrVersions.auto,
                        size: 180,
                        gapless: false,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    ElevatedButton(
                      onPressed: () async {
                        await _generateAndSavePDF(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6F61),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_printshop_rounded,
                              color: Colors.white),
                          SizedBox(width: 8),
                          Text('出力', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF263238),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code, color: Colors.white),
              SizedBox(width: 8),
              Text('QRコード', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}
