import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeButton extends StatelessWidget {
  final String data; // QR 코드에 포함할 데이터

  const QRCodeButton({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {
            // 버튼 클릭 시 다이얼로그 표시
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: const Color(0xffffffff),
                  title: const Text(
                    'QRコード',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  contentPadding: const EdgeInsets.all(20.0),
                  content: SizedBox(
                    width: 250,
                    height: 250,
                    child: Center(
                      child: QrImageView(
                        data: data,
                        version: QrVersions.auto,
                        size: 200.0,
                        gapless: false,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            print('出力');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6F61), // 요청한 배경색
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_printshop_rounded,
                                color: Colors.white,
                              ),
                              SizedBox(width: 16),
                              Text(
                                '出力',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        // const SizedBox(height: 8), // 세로 간격
                        // TextButton(
                        //   onPressed: () {
                        //     Navigator.of(context).pop();
                        //   },
                        //   child: const Text('閉じる'),
                        // ),
                      ],
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
            children: [
              Icon(Icons.qr_code, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "QRコード",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
