import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanned = false; // Prevent multiple pops

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QRコードをスキャン')),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() {
                    _isScanned = true;
                  });
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'カメラエラー: ${error.errorCode}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            },
          ),
          // Simple Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppColors.accentPrimary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Overlay Shape similar to the old one
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;
  final double cutOutBottomOffset;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
    this.cutOutBottomOffset = 0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final _cutOutSize = cutOutSize;
    final _cutOutBottomOffset = cutOutBottomOffset;
    final _borderRadius = borderRadius;
    final _borderLength = borderLength;
    final _borderColor = borderColor;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = _borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromCenter(
      center: rect.center + Offset(0, -_cutOutBottomOffset),
      width: _cutOutSize,
      height: _cutOutSize,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        rect,
        backgroundPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(_borderRadius),
        ),
        Paint()..blendMode = BlendMode.clear,
      )
      ..restore();

    final borderPath = _getBorderPath(cutOutRect, _borderLength, _borderRadius);

    canvas.drawPath(borderPath, borderPaint);
  }

  Path _getBorderPath(Rect cutOutRect, double length, double radius) {
    final path = Path();
    // Top Left
    path.moveTo(cutOutRect.left, cutOutRect.top + length);
    path.lineTo(cutOutRect.left, cutOutRect.top + radius);
    path.arcToPoint(
      Offset(cutOutRect.left + radius, cutOutRect.top),
      radius: Radius.circular(radius),
    );
    path.lineTo(cutOutRect.left + length, cutOutRect.top);

    // Top Right
    path.moveTo(cutOutRect.right - length, cutOutRect.top);
    path.lineTo(cutOutRect.right - radius, cutOutRect.top);
    path.arcToPoint(
      Offset(cutOutRect.right, cutOutRect.top + radius),
      radius: Radius.circular(radius),
    );
    path.lineTo(cutOutRect.right, cutOutRect.top + length);

    // Bottom Right
    path.moveTo(cutOutRect.right, cutOutRect.bottom - length);
    path.lineTo(cutOutRect.right, cutOutRect.bottom - radius);
    path.arcToPoint(
      Offset(cutOutRect.right - radius, cutOutRect.bottom),
      radius: Radius.circular(radius),
    );
    path.lineTo(cutOutRect.right - length, cutOutRect.bottom);

    // Bottom Left
    path.moveTo(cutOutRect.left + length, cutOutRect.bottom);
    path.lineTo(cutOutRect.left + radius, cutOutRect.bottom);
    path.arcToPoint(
      Offset(cutOutRect.left, cutOutRect.bottom - radius),
      radius: Radius.circular(radius),
    );
    path.lineTo(cutOutRect.left, cutOutRect.bottom - length);

    return path;
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
      cutOutBottomOffset: cutOutBottomOffset * t,
    );
  }
}
