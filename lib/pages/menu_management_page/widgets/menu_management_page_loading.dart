import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MenuManagementPageLoading extends StatelessWidget {
  final Color backgroundColor;
  final String loadingText;

  const MenuManagementPageLoading({
    super.key,
    this.backgroundColor = const Color(0xFFFF6F61),
    this.loadingText = '',
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16), // 最上位背景に丸みを帯びた角を適用
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1), // 半透明黒背景
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8), // 内部コンテナ背景色
              // borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpinKitSpinningLines(
                  color: backgroundColor,
                ),
                const SizedBox(height: 16),
                Text(
                  loadingText.isNotEmpty ? loadingText : 'データをロードしています...',
                  style: const TextStyle(
                    color: Color(0xFF263238),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
