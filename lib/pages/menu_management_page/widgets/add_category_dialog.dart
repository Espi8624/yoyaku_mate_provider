import 'package:flutter/material.dart';

class AddCategoryDialog extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onAddCategory;
  final List existingCategories;

  const AddCategoryDialog({
    super.key,
    required this.controller,
    required this.onAddCategory,
    required this.existingCategories,
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
                          "カテゴリー追加",
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
                          final categoryName = controller.text.trim();
                          if (categoryName.isNotEmpty &&
                              !existingCategories.contains(categoryName)) {
                            onAddCategory(categoryName);
                          }
                          Navigator.of(context).pop();
                          controller.clear();
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
