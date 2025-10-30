import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';
import '../../../../models/menu_list.dart';
import '../../../../widgets/common_dialogs/base_dialog.dart';
import '../../../../widgets/common_widgets/image_picker_box.dart';

class MenuFormDialog extends StatefulWidget {
  final MenuListItem? menuItem;
  final String storeId;
  final String category;

  const MenuFormDialog({
    super.key,
    this.menuItem,
    required this.storeId,
    required this.category,
  });

  @override
  State<MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends State<MenuFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  Uint8List? _tempImageBytes;
  bool _imageRemoved = false;
  bool get _isEditing => widget.menuItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.menuItem;
    _titleController = TextEditingController(text: item?.title);
    _descriptionController = TextEditingController(text: item?.description);
    _priceController =
        TextEditingController(text: item?.price.toStringAsFixed(0));
    _tempImageBytes = item?.tempImageBytes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();

      final menuItem = MenuListItem(
        id: _isEditing ? widget.menuItem!.id : '',
        storeId: _isEditing ? widget.menuItem!.storeId : widget.storeId,
        menuId: _isEditing
            ? widget.menuItem!.menuId
            : now.millisecondsSinceEpoch.toString(),
        category: _isEditing ? widget.menuItem!.category : widget.category,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        menuImageUrl: _imageRemoved
            ? ''
            : (_isEditing ? widget.menuItem!.menuImageUrl : ''),
        createdAt: _isEditing ? widget.menuItem!.createdAt : now,
        updatedAt: now,
        menuStatus: _isEditing ? widget.menuItem!.menuStatus : 'available',
        tempImageBytes: _tempImageBytes,
      );

      final result = {
        'menu': menuItem,
        'imageFile': _tempImageBytes,
        'imageRemoved': _imageRemoved,
      };

      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: _isEditing ? 'メニュー編集' : 'メニュー追加',
      width: 500,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImagePickerBox(
              initialImageBytes: _tempImageBytes,
              initialImageUrl: widget.menuItem?.menuImageUrl,
              onImagePicked: (bytes) {
                setState(() {
                  _tempImageBytes = bytes;

                  final currentImageUrl = widget.menuItem?.menuImageUrl ?? '';
                  _imageRemoved = bytes == null && currentImageUrl.isNotEmpty;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                  labelText: "メニュー名", border: OutlineInputBorder()),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'メニュー名を入力してください。'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                  labelText: "説明", border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                  labelText: "価格 (¥)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return '価格を入力してください。';
                if (double.tryParse(value) == null) return '有効な数値を入力してください。';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: AppColors.cardBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _submit,
                child: const Text("確認"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
