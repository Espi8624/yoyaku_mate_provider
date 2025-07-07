import 'package:flutter/material.dart';

import '../../../widgets/custom_snack_bar.dart';

Future<void> showBusinessHoursDialog(BuildContext context, Map<String, Map<String, int>> businessHours, List<String> days, {VoidCallback? onConfirm}) async {
  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '営業時間設定',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF263238)),
              onPressed: () => Navigator.pop(context),
              splashRadius: 20,
              tooltip: '닫기',
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 360),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var day in days) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        // 시작 시
                        Expanded(
                          child: DropdownButton<int>(
                            value: businessHours[day]!['startHour'],
                            items: List.generate(24, (index) => DropdownMenuItem(
                                  value: index,
                                  child: Text('$index時', style: const TextStyle(fontSize: 14, color: Color(0xFF263238))),
                                )),
                            onChanged: (value) {
                              setDialogState(() {
                                businessHours[day]!['startHour'] = value!;
                              });
                            },
                            isExpanded: true,
                            underline: Container(height: 1, color: const Color(0xFF263238)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // 시작 분
                        Expanded(
                          child: DropdownButton<int>(
                            value: businessHours[day]!['startMinute'],
                            items: List.generate(4, (index) => DropdownMenuItem(
                                  value: index * 15,
                                  child: Text('${index * 15}分', style: const TextStyle(fontSize: 14, color: Color(0xFF263238))),
                                )),
                            onChanged: (value) {
                              setDialogState(() {
                                businessHours[day]!['startMinute'] = value!;
                              });
                            },
                            isExpanded: true,
                            underline: Container(height: 1, color: const Color(0xFF263238)),
                          ),
                        ),
                        const Text(' ~ '),
                        // 종료 시
                        Expanded(
                          child: DropdownButton<int>(
                            value: businessHours[day]!['endHour'],
                            items: List.generate(24, (index) => DropdownMenuItem(
                                  value: index,
                                  child: Text('$index時', style: const TextStyle(fontSize: 14, color: Color(0xFF263238))),
                                )),
                            onChanged: (value) {
                              setDialogState(() {
                                businessHours[day]!['endHour'] = value!;
                              });
                            },
                            isExpanded: true,
                            underline: Container(height: 1, color: const Color(0xFF263238)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // 종료 분
                        Expanded(
                          child: DropdownButton<int>(
                            value: businessHours[day]!['endMinute'],
                            items: List.generate(4, (index) => DropdownMenuItem(
                                  value: index * 15,
                                  child: Text('${index * 15}分', style: const TextStyle(fontSize: 14, color: Color(0xFF263238))),
                                )),
                            onChanged: (value) {
                              setDialogState(() {
                                businessHours[day]!['endMinute'] = value!;
                              });
                            },
                            isExpanded: true,
                            underline: Container(height: 1, color: const Color(0xFF263238)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F61),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                // 유효성 검사: 각 요일별로 시작 < 종료인지 확인
                bool isValid = true;
                businessHours.forEach((day, times) {
                  final startHour = times['startHour']!;
                  final startMinute = times['startMinute']!;
                  final endHour = times['endHour']!;
                  final endMinute = times['endMinute']!;
                  if (startHour > endHour || (startHour == endHour && startMinute >= endMinute)) {
                    isValid = false;
                  }
                });
                if (!isValid) {
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(content: Text('閉店時間は開店時間より早くできません。')),
                  // );
                  CustomSnackBar.show(
                    context,
                    message: '閉店時間は開店時間より早くできません',
                    status: SnackBarStatus.error,
                  );
                  return;
                }
                Navigator.pop(context);
                if (onConfirm != null) onConfirm();
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(content: Text('営業時間が設定されました。')),
                // );
                CustomSnackBar.show(
                  context,
                  message: '営業時間が設定されました',
                  status: SnackBarStatus.info,
                );
              },
              child: const Text('確認'),
            ),
          ),
        ],
      ),
    ),
  );
}
