import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'dart:convert';

import 'package:yoyaku_mate_provider/services/waiting_service.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/custom_snack_bar.dart';

class AddWaitingDialog extends StatefulWidget {
  final VoidCallback onAddSuccess;
  final String storeId;

  const AddWaitingDialog({super.key, required this.onAddSuccess, required this.storeId});

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
  bool _isLoading = false;
  String? _error;
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final waitingService = WaitingService();
      await waitingService.createWaitingListItem(
        customerName: _customerNameController.text,
        partySize: int.parse(_partySizeController.text),
        nationality: _nationalityController.text,
        contact: _contactController.text,
        notes: _notesController.text,
        storeId: widget.storeId,
      );

      if (!mounted) return;

      widget.onAddSuccess();

      CustomSnackBar.show(
        context,
        message: '待機が正常に追加されました',
        status: SnackBarStatus.success,
      );

      Navigator.of(context).pop();
    } catch (e) {
      print('Error in _submitForm: $e');

      if (!mounted) return;

      if (e.toString().contains('Failed to create waiting list item')) {
        setState(() {
          _error = 'エラー: データの保存に失敗しました。';
          _isLoading = false;
        });
      } else {
        widget.onAddSuccess();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '新しい待機追加',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _customerNameController.clear();
                      _partySizeController.clear();
                      _nationalityController.clear();
                      _contactController.clear();
                      _notesController.clear();
                    },
                    icon: const Icon(Icons.close, color: Color(0xFF263238)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DropdownSearch<String>(
                asyncItems: (String? filter) async {
                  try {
                    final String response = await DefaultAssetBundle.of(context)
                        .loadString('assets/nationalities.json');
                    final data = json.decode(response);
                    List<String> nationalities =
                        List<String>.from(data['nationalities']);

                    if (filter != null && filter.isNotEmpty) {
                      nationalities = nationalities
                          .where((item) =>
                              item.toLowerCase().contains(filter.toLowerCase()))
                          .toList();
                    }

                    print(
                        'Loaded ${nationalities.length} nationalities for filter: $filter');
                    return nationalities;
                  } catch (e) {
                    print('Error loading nationalities: $e');
                    return ['データ読み込みエラー'];
                  }
                },
                selectedItem: _selectedNationality,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedNationality = newValue;
                    _nationalityController.text = newValue ?? '';
                  });
                },
                enabled: true,
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: '国籍',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF263238), width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    labelStyle: TextStyle(color: Color(0xFF263238)),
                    floatingLabelStyle: TextStyle(color: Color(0xFF263238)),
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(
                      hintText: '国籍を検索',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  constraints:
                      const BoxConstraints(maxHeight: 300, maxWidth: 350),
                  listViewProps: const ListViewProps(
                    physics: ClampingScrollPhysics(),
                    cacheExtent: 1000.0,
                  ),
                  emptyBuilder: (context, searchEntry) => const Center(
                    child: Text('データが見つかりません'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _customerNameController,
                cursorColor: const Color(0xFF263238),
                decoration: const InputDecoration(
                  labelText: 'お客様名',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF263238), width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  labelStyle: TextStyle(color: Color(0xFF263238)),
                  floatingLabelStyle: TextStyle(color: Color(0xFF263238)),
                ),
                style: const TextStyle(color: Color(0xFF263238)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'お客様名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _partySizeController,
                cursorColor: const Color(0xFF263238),
                decoration: const InputDecoration(
                  labelText: '人数',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF263238), width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  labelStyle: TextStyle(color: Color(0xFF263238)),
                  floatingLabelStyle: TextStyle(color: Color(0xFF263238)),
                ),
                style: const TextStyle(color: Color(0xFF263238)),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '人数を入力してください';
                  }
                  if (int.tryParse(value) == null) {
                    return '有効な数字を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactController,
                cursorColor: const Color(0xFF263238),
                decoration: const InputDecoration(
                  labelText: '連絡先',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF263238), width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  labelStyle: TextStyle(color: Color(0xFF263238)),
                  floatingLabelStyle: TextStyle(color: Color(0xFF263238)),
                ),
                style: const TextStyle(color: Color(0xFF263238)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '連絡先を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                cursorColor: const Color(0xFF263238),
                decoration: const InputDecoration(
                  labelText: '要望事項',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF263238), width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  labelStyle: TextStyle(color: Color(0xFF263238)),
                  floatingLabelStyle: TextStyle(color: Color(0xFF263238)),
                ),
                style: const TextStyle(color: Color(0xFF263238)),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F61),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('追加'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
