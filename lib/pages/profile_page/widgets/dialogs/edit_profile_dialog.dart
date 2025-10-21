import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/base_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/custom_snack_bar.dart';

class EditProfileDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final bool isPassword;

  const EditProfileDialog({
    super.key,
    required this.title,
    required this.initialValue,
    this.isPassword = false,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _controller;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);

    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  Future<void> _changePassword() async {
    // form有効性検査
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in.");
      if (user.email == null) throw Exception("User email is not available.");

      // Firebaseに再認証(現在のバスワード確認)
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);

      // 再認証成功時、新しいパスワードでアップデート
      await user.updatePassword(_newPasswordController.text.trim());

      if (mounted) {
        Navigator.of(context).pop();
        CustomSnackBar.show(
          context,
          message: 'パスワードが正常に変更されました。',
          status: SnackBarStatus.success,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'エラーが発生しました。';
        if (e.code == 'wrong-password') {
          errorMessage = '現在のパスワードが正しくありません。';
        } else if (e.code == 'weak-password') {
          errorMessage = 'パスワードは6文字以上で入力してください。';
        }
        CustomSnackBar.show(context,
            message: errorMessage, status: SnackBarStatus.error);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context,
            message: '予期せぬエラーが発生しました。', status: SnackBarStatus.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPassword) {
      return _buildPasswordChangeDialog();
    } else {
      return _buildDefaultDialog();
    }
  }

  Widget _buildDefaultDialog() {
    return BaseDialog(
      title: widget.title,
      width: 400,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '新しい${widget.title}',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
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
    );
  }

  Widget _buildPasswordChangeDialog() {
    return BaseDialog(
      title: widget.title,
      width: 400,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPasswordField(
                controller: _currentPasswordController, label: '現在のパスワード'),
            const SizedBox(height: 16),
            _buildPasswordField(
                controller: _newPasswordController, label: '新しいパスワード'),
            const SizedBox(height: 16),
            _buildPasswordField(
                controller: _confirmPasswordController,
                label: '新しいパスワードの確認',
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'パスワードが一致しません。';
                  }
                  return null;
                }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white))
                    : const Text('変更'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'この項目は必須です。';
            }
            if (value.length < 6) {
              return '6文字以上で入力してください。';
            }
            return null;
          },
    );
  }
}
