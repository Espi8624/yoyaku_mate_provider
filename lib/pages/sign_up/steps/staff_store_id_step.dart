import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/sign_up_viewmodel.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/qr_scanner_view.dart';
import 'package:yoyaku_mate_provider/widgets/common_buttons/action_button.dart';

class StaffStoreIdStep extends StatefulWidget {
  final TextEditingController storeIdController;
  final VoidCallback onNext;

  const StaffStoreIdStep({
    super.key,
    required this.storeIdController,
    required this.onNext,
  });

  @override
  State<StaffStoreIdStep> createState() => _StaffStoreIdStepState();
}

class _StaffStoreIdStepState extends State<StaffStoreIdStep> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignUpViewModel>();
    final isLoading = vm.isLoading;
    final errorMessage = vm.errorMessage;

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('店舗ID入力',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('所属する店舗のIDを入力してください。',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            _buildTextField(
              controller: widget.storeIdController,
              label: '店舗ID',
            ),
            const SizedBox(height: 8),
            const Text('※管理者から共有されたIDを入力してください',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            if (errorMessage != null)
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(errorMessage,
                      style: const TextStyle(color: AppColors.error))),
            const SizedBox(height: 40),
            ActionButton(label: '次へ', onPressed: _submit, isLoading: isLoading),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onNext();
    }
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerView()),
    );

    if (result != null && mounted) {
      setState(() {
        widget.storeIdController.text = result;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
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
        suffixIcon: IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: _scanQRCode,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '店舗IDを入力してください。';
        return null;
      },
    );
  }
}
