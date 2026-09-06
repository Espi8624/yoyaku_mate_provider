import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/services/address_service.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

/// 本人(個人)住所の入力欄グループ
///
/// 郵便番号検索(zipcloud API)で都道府県・市区町村を内部的に補完し、
/// 画面上には郵便番号・住所(番地まで)・建物名のみを表示する。
/// 店舗登録時の住所入力(store_wizard_steps.dart)と同じ挙動
class PersonalAddressFields extends StatefulWidget {
  final TextEditingController zipCodeController;
  final TextEditingController prefectureController;
  final TextEditingController cityController;
  final TextEditingController addressController;
  final TextEditingController buildingController;

  const PersonalAddressFields({
    super.key,
    required this.zipCodeController,
    required this.prefectureController,
    required this.cityController,
    required this.addressController,
    required this.buildingController,
  });

  @override
  State<PersonalAddressFields> createState() => _PersonalAddressFieldsState();
}

class _PersonalAddressFieldsState extends State<PersonalAddressFields> {
  bool _isLoadingAddress = false;

  Future<void> _searchAddress() async {
    final zipCode = widget.zipCodeController.text.replaceAll('-', '');
    if (zipCode.length != 7) {
      ToastWidget.show(context, '郵便番号(7桁)を入力してください', type: ToastType.error);
      return;
    }

    setState(() => _isLoadingAddress = true);
    FocusScope.of(context).unfocus();

    final service = AddressService();
    final address = await service.searchAddress(zipCode);

    if (!mounted) return;
    setState(() => _isLoadingAddress = false);

    if (address != null) {
      setState(() {
        widget.prefectureController.text = address.prefecture;
        widget.cityController.text = address.city;
        widget.addressController.text = address.fullAddress;
      });
      ToastWidget.show(context, '住所を自動入力しました', type: ToastType.success);
    } else {
      ToastWidget.show(context, '郵便番号が見つかりませんでした', type: ToastType.error);
    }
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return '住所を入力してください。';
    }
    // 番地まで含まれているかチェック(半角/全角の数字+ハイフンパターン)
    final hasBlockNumber =
        RegExp(r'[0-9０-９]+.*[-−].*[0-9０-９]+').hasMatch(value);
    if (!hasBlockNumber) {
      return '住所は番地まで正しく入力してください (例: 1-2-3)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _buildTextField(
                controller: widget.zipCodeController,
                label: '郵便番号 (ハイフンなし)',
                inputType: TextInputType.number,
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoadingAddress
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('住所検索'),
                ),
              ),
            ),
          ],
        ),
        _buildTextField(
          controller: widget.addressController,
          label: '住所',
          validator: _validateAddress,
        ),
        _buildTextField(
          controller: widget.buildingController,
          label: '建物名・部屋番号 (任意)',
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.accentPrimary, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
