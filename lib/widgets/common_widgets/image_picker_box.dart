import 'dart:typed_data';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class ImagePickerBox extends StatefulWidget {
  final Uint8List? initialImageBytes;
  final String? initialImageUrl;
  final Function(Uint8List) onImagePicked;

  const ImagePickerBox({
    super.key,
    this.initialImageBytes,
    this.initialImageUrl,
    required this.onImagePicked,
  });

  @override
  State<ImagePickerBox> createState() => _ImagePickerBoxState();
}

class _ImagePickerBoxState extends State<ImagePickerBox> {
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.initialImageBytes;
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _imageBytes = result.files.single.bytes!;
      });
      widget.onImagePicked(_imageBytes!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(8),
        dashPattern: const [6, 3],
        color: AppColors.mediumGrey,
        strokeWidth: 1.5,
        child: SizedBox(
          height: 160,
          width: double.infinity,
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
      );
    }
    if (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(widget.initialImageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder()),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Text('+ クリックして画像を選択', style: TextStyle(color: AppColors.mediumGrey)),
    );
  }
}