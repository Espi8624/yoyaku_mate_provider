import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerBox extends StatefulWidget {
  final Uint8List? initialImageBytes;
  final String? initialImageUrl;
  final Function(Uint8List?) onImagePicked;
  final double size;

  const ImagePickerBox({
    super.key,
    this.initialImageBytes,
    this.initialImageUrl,
    required this.onImagePicked,
    this.size = 200,
  });

  @override
  State<ImagePickerBox> createState() => _ImagePickerBoxState();
}

class _ImagePickerBoxState extends State<ImagePickerBox> {
  Uint8List? _imageBytes;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.initialImageBytes;
    _imageUrl = widget.initialImageUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
      requestFullMetadata: false, // iOS 시뮬레이터 멈춤 버그 방지
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageUrl = null;
      });
      widget.onImagePicked(bytes);
    }
  }

  // イメージ除去メソッド
  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageUrl = null;
    });
    widget.onImagePicked(null);
  }

  bool get _hasImage =>
      _imageBytes != null || (_imageUrl != null && _imageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          // イメージ表示領域
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: _hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _imageBytes != null
                          ? Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline,
                                          size: 40, color: Colors.red),
                                      SizedBox(height: 8),
                                      Text('画像の読み込みに失敗しました',
                                          style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                );
                              },
                            ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate,
                            size: 50, color: Colors.grey.shade600),
                        SizedBox(height: 8),
                        Text(
                          'タップして画像を選択',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // イメージ除去ボタン
          if (_hasImage)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _removeImage,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // イメージ変更ボタン
          if (_hasImage)
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        '変更',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
