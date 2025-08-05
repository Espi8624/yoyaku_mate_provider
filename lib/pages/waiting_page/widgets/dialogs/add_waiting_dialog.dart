// import 'dart:convert';
// import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';
import '../../../../widgets/common_dialogs/base_dialog.dart';

class AddWaitingDialog extends StatefulWidget {
  const AddWaitingDialog({super.key});

  @override
  State<AddWaitingDialog> createState() => _AddWaitingDialogState();
}

class _AddWaitingDialogState extends State<AddWaitingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _partySizeController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _contactController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedNationality;

  @override
  void initState() {
    super.initState();
    _selectedNationality = "JAPAN";
    _nationalityController.text = _selectedNationality ?? '';
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _partySizeController.dispose();
    _nationalityController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newItemData = {
        'customerName': _customerNameController.text.trim(),
        'partySize': int.parse(_partySizeController.text),
        'nationality': _nationalityController.text,
        'contact': _contactController.text.trim(),
        'notes': _notesController.text.trim(),
      };
      Navigator.of(context).pop(newItemData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: '新しい待機追加',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 国籍ドロップダウン (DropdownSearch)
            // DropdownSearch<String>(
            //   asyncItems: (filter) async {
            //     final String response = await DefaultAssetBundle.of(context)
            //         .loadString('assets/nationalities.json');
            //     final data = json.decode(response);
            //     return List<String>.from(data['nationalities']);
            //   },
            //   selectedItem: _selectedNationality,
            //   onChanged: (newValue) {
            //     setState(() {
            //       _selectedNationality = newValue;
            //       _nationalityController.text = newValue ?? '';
            //     });
            //   },
            //   popupProps: const PopupProps.menu(showSearchBox: true),
            //   dropdownDecoratorProps: const DropDownDecoratorProps(
            //     dropdownSearchDecoration: InputDecoration(
            //         labelText: '国籍', border: OutlineInputBorder()),
            //   ),
            // ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                  labelText: 'お客様名', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'お客様名を入力してください' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _partySizeController,
              decoration: const InputDecoration(
                  labelText: '人数', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return '人数を入力してください';
                if (int.tryParse(v) == null) return '有効な数字を入力してください';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                  labelText: '連絡先', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                  labelText: '要望事項', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: AppColors.cardBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _submitForm,
                child: const Text("追加"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
