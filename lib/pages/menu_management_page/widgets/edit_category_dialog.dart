import 'package:flutter/material.dart';

class EditCategoryDialog extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onEditCategory;
  final List<String> existingCategories;
  final String currentCategoryName;

  const EditCategoryDialog({
    super.key,
    required this.controller,
    required this.onEditCategory,
    required this.existingCategories,
    required this.currentCategoryName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // Dialog 外クリック時閉じる
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Dialog 内クリック時、閉じないようにする
            child: Dialog(
              backgroundColor: const Color(0xffffffff),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "カテゴリー編集",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF263238),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            controller.clear();
                          },
                          icon: const Icon(Icons.close, color: Color(0xFF263238)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'カテゴリー名',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6F61),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          final newCategoryName = controller.text.trim();
                          if (newCategoryName.isNotEmpty &&
                              !existingCategories.contains(newCategoryName)) {
                            onEditCategory(newCategoryName);
                            Navigator.of(context).pop();
                            controller.clear();
                          } else if (newCategoryName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('カテゴリー名を入力してください。')),
                            );
                          } else if (existingCategories.contains(newCategoryName)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('同じカテゴリー名が既に存在します。')),
                            );
                          }
                        },
                        child: const Text("確認"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
