import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/base_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

class EditProfileDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final String? initialFurigana; // New
  final bool isPassword;
  final bool isName;

  const EditProfileDialog({
    super.key,
    required this.title,
    required this.initialValue,
    this.initialFurigana, // New
    this.isPassword = false,
    this.isName = false,
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

  // 名前分割編集用
  late final TextEditingController _lastNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameKanaController; // New
  late final TextEditingController _firstNameKanaController; // New

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);

    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // 名前分割初期化
    if (widget.isName) {
      _initNameControllers(widget.initialValue, (last, first) {
        _lastNameController = TextEditingController(text: last);
        _firstNameController = TextEditingController(text: first);
      });
      _initNameControllers(widget.initialFurigana ?? '', (last, first) {
        _lastNameKanaController = TextEditingController(text: last);
        _firstNameKanaController = TextEditingController(text: first);
      });
    } else {
      _lastNameController = TextEditingController();
      _firstNameController = TextEditingController();
      _lastNameKanaController = TextEditingController();
      _firstNameKanaController = TextEditingController();
    }
  }

  void _initNameControllers(String fullValue, Function(String, String) onSet) {
    final raw = fullValue.replaceAll(RegExp(r'[\u3000\s]+'), ' ').trim();
    if (raw.isEmpty) {
      onSet('', '');
    } else {
      final parts = raw.split(RegExp(r'\s+'));
      if (parts.length == 1) {
        onSet(parts[0], '');
      } else {
        onSet(parts.first, parts.sublist(1).join(' '));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _lastNameKanaController.dispose();
    _firstNameKanaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isName) {
      final lastName = _lastNameController.text.trim();
      final firstName = _firstNameController.text.trim();
      final lastNameKana = _lastNameKanaController.text.trim();
      final firstNameKana = _firstNameKanaController.text.trim();

      if (lastName.isEmpty && firstName.isEmpty) {
        Navigator.of(context).pop();
        return;
      }

      final fullName = '$lastName $firstName'.trim();
      final fullKana = '$lastNameKana $firstNameKana'.trim();

      // Return Map for multiple fields
      Navigator.of(context).pop({
        'name': fullName,
        'name_furigana': fullKana,
      });
    } else {
      Navigator.of(context).pop(_controller.text);
    }
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
        ToastWidget.show(
          context,
          'パスワードが正常に変更されました。',
          type: ToastType.success,
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
        ToastWidget.show(context, errorMessage, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        ToastWidget.show(context, '予期せぬエラーが発生しました。', type: ToastType.error);
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
    } else if (widget.isName) {
      return _buildNameEditDialog();
    } else {
      return _buildDefaultDialog();
    }
  }

  Widget _buildNameEditDialog() {
    return BaseDialog(
      title: widget.title,
      width: 400,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lastNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: '姓',
                    hintText: '山田',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: '名',
                    hintText: '太郎',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lastNameKanaController,
                  decoration: InputDecoration(
                    labelText: 'フリガナ (姓)',
                    hintText: 'ヤマダ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _firstNameKanaController,
                  decoration: InputDecoration(
                    labelText: 'フリガナ (名)',
                    hintText: 'タロウ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
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
                    return 'パスワード가一致しません。';
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
