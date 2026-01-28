import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/services/address_service.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/base_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

/// 住所編集用ダイアログ
/// 郵便番号検索機能を提供し、店舗プロフィールの住所情報を更新するために使用されます。
class EditAddressDialog extends StatefulWidget {
  final String initialZipCode;
  final String initialPrefecture;
  final String initialCity;
  final String initialAddress;
  final String initialBuilding;

  const EditAddressDialog({
    super.key,
    required this.initialZipCode,
    required this.initialPrefecture,
    required this.initialCity,
    required this.initialAddress,
    required this.initialBuilding,
  });

  @override
  State<EditAddressDialog> createState() => _EditAddressDialogState();
}

class _EditAddressDialogState extends State<EditAddressDialog> {
  final _formKey = GlobalKey<FormState>();

  // 各住所フィールド用コントローラー
  late final TextEditingController _zipCodeController;
  late final TextEditingController _prefectureController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _buildingController;

  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    // 初期値の設定
    _zipCodeController = TextEditingController(text: widget.initialZipCode);
    _prefectureController =
        TextEditingController(text: widget.initialPrefecture);
    _cityController = TextEditingController(text: widget.initialCity);
    _addressController = TextEditingController(text: widget.initialAddress);
    _buildingController = TextEditingController(text: widget.initialBuilding);
  }

  @override
  void dispose() {
    _zipCodeController.dispose();
    _prefectureController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _buildingController.dispose();
    super.dispose();
  }

  /// 郵便番号から住所を検索するメソッド
  /// [AddressService] を使用して ZipCloud API から住所情報を取得します。
  Future<void> _searchAddress() async {
    final zipCode = _zipCodeController.text.replaceAll('-', '');
    if (zipCode.length != 7) {
      ToastWidget.show(context, '郵便番号(7桁)を入力してください', type: ToastType.error);
      return;
    }

    setState(() => _isLoadingAddress = true);
    FocusScope.of(context).unfocus(); // キーボードを閉じる

    try {
      final service = AddressService();
      final address = await service.searchAddress(zipCode);

      if (!mounted) return;

      if (address != null) {
        setState(() {
          // 取得した住所情報をコントローラーにセット
          // 店舗登録画面と同様に、画面上は「住所」フィールドにフルアドレスを表示し、
          // 都道府県・市区町村は内部的に保持する構成にしています。
          _prefectureController.text = address.prefecture;
          _cityController.text = address.city;
          _addressController.text = address.fullAddress;
        });
        ToastWidget.show(context, '住所を自動入力しました', type: ToastType.success);
      } else {
        ToastWidget.show(context, '郵便番号が見つかりませんでした', type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        ToastWidget.show(context, 'エラーが発生しました', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  /// 入力内容を確定し、前の画面にデータを戻すメソッド
  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'zip_code': _zipCodeController.text.trim(),
        'prefecture': _prefectureController.text.trim(),
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'building': _buildingController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: '住所の編集',
      width: 500,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 郵便番号入力欄と検索ボタン
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _zipCodeController,
                    label: '郵便番号 (ハイフンなし)',
                    inputType: TextInputType.number,
                    validator: (v) =>
                        v!.isEmpty ? '必須' : (v.length != 7 ? '7桁' : null),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoadingAddress ? null : _searchAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoadingAddress
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('検索'),
                    ),
                  ),
                ),
              ],
            ),

            // 店舗追加画面のロジックに合わせて、都道府県・市区町村フィールドは非表示にしています。
            // 郵便番号検索によって内部的にデータが入力されます。

            // 住所 (番地) 入力欄
            _buildTextField(
                controller: _addressController,
                label: '住所',
                validator: (v) => v!.isEmpty ? '住所を入力してください' : null),
            // 建物名・部屋番号入力欄
            _buildTextField(
                controller: _buildingController, label: '建物名・部屋番号 (任意)'),
            const SizedBox(height: 24),
            // 確認ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('確認'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: validator,
      ),
    );
  }
}
