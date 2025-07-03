import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:yoyaku_mate_provider/models/menu_list.dart';

class AddMenuDialog extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final String category;
  final String storeId;

  const AddMenuDialog({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.priceController,
    required this.category,
    required this.storeId,
  });

  @override
  _AddMenuDialogState createState() => _AddMenuDialogState();
}

class _AddMenuDialogState extends State<AddMenuDialog> {
  Uint8List? tempImageBytes;

  @override
  void initState() {
    super.initState();
    widget.titleController.clear();
    widget.descriptionController.clear();
    widget.priceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // 다이얼로그 바깥 클릭 시 닫힘
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // 내부 클릭 시 닫히지 않음
            child: Dialog(
              backgroundColor: const Color(0xffffffff),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "メニュー追加",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.titleController.clear();
                              widget.descriptionController.clear();
                              widget.priceController.clear();
                            },
                            icon: const Icon(Icons.close, color: Color(0xFF263238)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () async {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );
                          if (result != null && result.files.single.bytes != null) {
                            setState(() {
                              tempImageBytes = result.files.single.bytes!;
                            });
                          }
                        },
                        child: DottedBorder(
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(8),
                          dashPattern: const [6, 3],
                          color: Colors.grey,
                          strokeWidth: 1.5,
                          child: SizedBox(
                            height: 160,
                            width: double.infinity,
                            child: tempImageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      tempImageBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  )
                                : const Center(
                                    child: Text(
                                      '+ クリックして画像を選択',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: widget.titleController,
                        decoration: const InputDecoration(
                          labelText: "メニュー名",
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: widget.descriptionController,
                        decoration: const InputDecoration(
                          labelText: "説明",
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: widget.priceController,
                        decoration: const InputDecoration(
                          labelText: "価格 (¥)",
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6F61),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                if (widget.titleController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('メニュー名を入力してください。')),
                                  );
                                  return;
                                }
                                if (widget.priceController.text.trim().isEmpty ||
                                    double.tryParse(widget.priceController.text) ==
                                        null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('有効な価格を入力してください。')),
                                  );
                                  return;
                                }
                                final menuItem = MenuListItem(
                                  id: '',
                                  storeId: widget.storeId,
                                  menuId: DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                                  category: widget.category,
                                  title: widget.titleController.text,
                                  description: widget.descriptionController.text,
                                  price: double.parse(widget.priceController.text),
                                  imageUrl: '',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  menuStatus: 'available',
                                  tempImageBytes: tempImageBytes,
                                );
                                Navigator.of(context).pop(menuItem);
                              },
                              child: const Text("確認"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
