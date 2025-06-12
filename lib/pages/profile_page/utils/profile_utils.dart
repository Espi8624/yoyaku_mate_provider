import 'package:flutter/material.dart';

class ProfileUtils {
  // 섹션 제목 위젯
  static Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238)),
      ),
    );
  }

  // 설정 항목 위젯
  static Widget buildSettingItem(
      String title, String subtitle, Widget? trailing,
      {VoidCallback? onTap}) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(fontSize: 16, color: Color(0xFF263238))),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 13, color: Colors.grey)),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  // 섹션 박스 위젯
  static Widget sectionBox({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: _boxDecoration(),
      child: child,
    );
  }

  // 박스 데코레이션
  static BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1)),
      ],
    );
  }

  // 텍스트 편집 다이얼로그
  static Future<void> showEditDialog({
    required BuildContext context,
    required String title,
    required TextEditingController controller,
    required Function(String) onSave,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, size: 24, color: Color(0xFF263238)),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: title,
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF263238)),
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F61),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (controller.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('値を入力してください。')),
                  );
                  return;
                }
                onSave(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('変更事項を保存しました。')),
                );
              },
              child: const Text('確認'),
            ),
          ),
        ],
      ),
    );
  }
}
