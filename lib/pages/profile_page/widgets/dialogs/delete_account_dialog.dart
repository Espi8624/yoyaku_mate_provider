import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/providers/session_providers.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/session_service.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/base_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

/// 会員退会用ダイアログ
///
/// 本人確認のためパスワードの再入力(Firebase reauthenticateWithCredential)を
/// 必須にした上で、サーバー側に退会(ソフトデリート)を依頼する。氏名・電話番号
/// などの連絡先は削除されず、ログインのみ不可になる(サーバー側の方針)。
/// 店舗を保有したままのマネージャーはサーバー側で拒否される(store_info参照)
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('ログイン情報が確認できません。再ログインしてください。');
      }

      // 本人確認: パスワード再入力による再認証
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);

      // サーバー側でuser_infoドキュメント + Firebase Authアカウントを削除
      await ref.read(profileActionsProvider.notifier).deleteAccount();

      // サーバー側は既に削除済みだが、端末側のセッション・SDK状態もクリアする
      await SessionService.instance.clear();
      await FirebaseAuth.instance.signOut();

      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'エラーが発生しました。';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'パスワードが正しくありません。';
      }
      ToastWidget.show(context, message, type: ToastType.error);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : '予期しないエラーが発生しました: $e';
      ToastWidget.show(context, message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: '退会',
      width: 400,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '退会すると、このアカウントではログインできなくなります。\n'
              '必要な連絡のため、氏名・電話番号などの情報は運営側で保持されます。\n'
              '続行するには現在のパスワードを入力してください。',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '現在のパスワード',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'パスワードを入力してください。';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white))
                    : const Text('退会する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
