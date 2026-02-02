import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';
import '../../../../models/menu_list.dart';
import '../../../../services/translation_service.dart';
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
  bool _isPreOrderAvailable = false;
  bool _isLoading = false;

  // Existing translations to preserve if not re-translating
  Map<String, String> _titleTranslations = {};
  Map<String, String> _descTranslations = {};

  bool get _isEditing => widget.menuItem != null;

  static const List<String> _targetLanguages = [
    'English',
    'Korean',
    'Chinese', // Simplified
    'Traditional Chinese', // Taiwan
    'Spanish',
    'French',
    'German',
    'Italian',
    'Arabic',
    'Russian',
    'Portuguese',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.menuItem;
    _titleController = TextEditingController(text: item?.title);
    _descriptionController = TextEditingController(text: item?.description);
    _priceController =
        TextEditingController(text: item?.price.toStringAsFixed(0));
    _tempImageBytes = item?.tempImageBytes;
    _isPreOrderAvailable = item?.isPreOrderAvailable ?? false;

    if (item != null) {
      _titleTranslations = Map.from(item.titleTranslations);
      _descTranslations = Map.from(item.descriptionTranslations);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _performTranslations(String title, String desc) async {
    final titleChanged = widget.menuItem?.title != title;
    final descChanged = widget.menuItem?.description != desc;
    final isNew = widget.menuItem == null;

    final inputMap = <String, String>{};

    // Determine if Title needs translation
    bool needTitle = titleChanged || isNew;
    if (!needTitle && title.isNotEmpty) {
      // Check if any target language is missing
      for (final lang in _targetLanguages) {
        if (!_titleTranslations.containsKey(lang)) {
          needTitle = true;
          break;
        }
      }
    }
    if (needTitle && title.isNotEmpty) {
      inputMap['t_0'] = title;
    }

    // Determine if Description needs translation
    bool needDesc = desc.isNotEmpty && (descChanged || isNew);
    if (!needDesc && desc.isNotEmpty) {
      for (final lang in _targetLanguages) {
        if (!_descTranslations.containsKey(lang)) {
          needDesc = true;
          break;
        }
      }
    }
    if (needDesc) {
      inputMap['d_0'] = desc;
    }

    if (inputMap.isEmpty) {
      // If description became empty, clear translations
      if (desc.isEmpty) _descTranslations.clear();
      return;
    }

    // Call API once for all languages
    final result = await TranslationService().translateToMultipleLanguages(
      inputMap,
      _targetLanguages,
      smartMenuMode: true,
    );

    // Apply results
    result.forEach((lang, transMap) {
      if (inputMap.containsKey('t_0') && transMap.containsKey('t_0')) {
        _titleTranslations[lang] = transMap['t_0']!;
      }
      if (inputMap.containsKey('d_0') && transMap.containsKey('d_0')) {
        _descTranslations[lang] = transMap['d_0']!;
      }
    });

    // Final cleanup
    if (desc.isEmpty) {
      _descTranslations.clear();
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _performTranslations(
          _titleController.text.trim(),
          _descriptionController.text.trim(),
        );

        if (!mounted) return;

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
          isPreOrderAvailable: _isPreOrderAvailable,
          tempImageBytes: _tempImageBytes,
          titleTranslations: _titleTranslations,
          descriptionTranslations: _descTranslations,
        );

        final result = {
          'menu': menuItem,
          'imageFile': _tempImageBytes,
          'imageRemoved': _imageRemoved,
        };

        Navigator.of(context).pop(result);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Translation failed: $e. Saving anyway.')),
          );
          // Proceed to save even if translation fails?
          // Maybe better to alert user.
          // For now, let's stop and allow retry.
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: _isEditing ? 'メニュー編集' : 'メニュー追加',
      width: 500,
      content: Stack(
        children: [
          Form(
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
                      final currentImageUrl =
                          widget.menuItem?.menuImageUrl ?? '';
                      _imageRemoved =
                          bytes == null && currentImageUrl.isNotEmpty;
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
                    if (double.tryParse(value) == null)
                      return '有効な数値を入力してください。';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("事前注文可能"),
                  subtitle: const Text("待機登録時にこのメニューを表示します"),
                  value: _isPreOrderAvailable,
                  onChanged: (value) {
                    setState(() {
                      _isPreOrderAvailable = value;
                    });
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
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text("確認"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
