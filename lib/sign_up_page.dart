// import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/models/provider_profile.dart';
import 'package:yoyaku_mate_provider/models/store_profile.dart';
import 'package:yoyaku_mate_provider/models/user_profile.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen_viewmodel.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';
import 'package:yoyaku_mate_provider/utils/phone_formatter.dart';

import 'package:yoyaku_mate_provider/routes.dart' show setSignUpInProgress;
import 'package:yoyaku_mate_provider/widgets/common_dialogs/confirmation_dialog.dart';

class SignUpPage extends StatefulWidget {
  final String? mode; // 'add_store' or null

  const SignUpPage({super.key, this.mode});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  String? _role;
  bool _isLoading = false;
  String? _errorMessage;

  // 電話番号認証関連
  String? _verificationId;
  bool _isPhoneVerified = false;
  int? _resendToken;

  // メール認証関連
  bool _isEmailVerified = false;
  User? _pendingUser; // 認証待機中のユーザー

  late PageController _pageController;
  int _currentPageIndex = 0;

  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();

  // コントローラー初期化
  final TextEditingController managerEmailController = TextEditingController();
  final TextEditingController managerPasswordController =
      TextEditingController();
  final TextEditingController managerConfirmPasswordController =
      TextEditingController();
  final TextEditingController managerPhoneController = TextEditingController();
  // ★変更: 名前を姓／名で分割
  final TextEditingController managerLastNameController =
      TextEditingController();
  final TextEditingController managerFirstNameController =
      TextEditingController();
  // ★追加: 読み仮名コントローラー
  final TextEditingController managerLastNameKanaController =
      TextEditingController();
  final TextEditingController managerFirstNameKanaController =
      TextEditingController();
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController storeAddressController = TextEditingController();
  final TextEditingController storePhoneController = TextEditingController();

  final TextEditingController staffStoreIdController = TextEditingController();
  final TextEditingController staffEmailController = TextEditingController();
  final TextEditingController staffPasswordController = TextEditingController();
  final TextEditingController staffConfirmPasswordController =
      TextEditingController();
  final TextEditingController staffPhoneController = TextEditingController();
  // ★変更: 職員名も姓／名で分割
  final TextEditingController staffLastNameController = TextEditingController();
  final TextEditingController staffFirstNameController =
      TextEditingController();
  // ★追加: 職員読み仮名コントローラー
  final TextEditingController staffLastNameKanaController =
      TextEditingController();
  final TextEditingController staffFirstNameKanaController =
      TextEditingController();

  // 認証コード入力用
  final TextEditingController verificationCodeController =
      TextEditingController();

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;

    final uri = GoRouterState.of(context).uri;
    final roleParam = uri.queryParameters['role'];

    int initialPage = 0;

    if (widget.mode == 'add_store') {
      _role = roleParam ?? 'manager';
      if (_role == 'staff') {
        initialPage = 6; // 職員情報入力(店舗番号入力) index
      } else {
        initialPage = 7; // 店舗情報入力 index (manager)
      }
    }

    _pageController = PageController(initialPage: initialPage);

    _pageController.addListener(_pageControllerListener);

    if (widget.mode == 'add_store') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final profileVM = context.read<ProfileScreenViewModel>();
          final userProfile = profileVM.userProfile;

          if (userProfile != null) {
            managerEmailController.text = userProfile.email;
            managerPhoneController.text = userProfile.phone;
            // ★変更: 名前を姓・名に分割
            final rawName =
                userProfile.name.replaceAll(RegExp(r'[\u3000\s]+'), ' ').trim();
            if (rawName.isEmpty) {
              managerLastNameController.text = '';
              managerFirstNameController.text = '';
            } else {
              final parts = rawName.split(RegExp(r'\s+'));
              if (parts.length == 1) {
                managerLastNameController.text = parts[0];
                managerFirstNameController.text = '';
              } else {
                managerLastNameController.text = parts.first;
                managerFirstNameController.text = parts.sublist(1).join(' ');
              }
            }
          } else {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              managerEmailController.text = currentUser.email ?? '';
            }
          }
        }
      });
    }
  }

  void _pageControllerListener() {
    if (!mounted) return;
    final newPage = _pageController.page?.round();
    if (newPage != null && newPage != _currentPageIndex) {
      setState(() {
        _currentPageIndex = newPage;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_pageControllerListener);
    _pageController.dispose();
    managerEmailController.dispose();
    managerPasswordController.dispose();
    managerConfirmPasswordController.dispose();
    managerPhoneController.dispose();
    // ★変更: 分割したコントローラーをdispose
    managerLastNameController.dispose();
    managerFirstNameController.dispose();
    managerLastNameKanaController.dispose();
    managerFirstNameKanaController.dispose();
    storeNameController.dispose();
    storeAddressController.dispose();
    storePhoneController.dispose();
    staffStoreIdController.dispose();
    staffEmailController.dispose();
    staffPasswordController.dispose();
    staffConfirmPasswordController.dispose();
    staffPhoneController.dispose();
    // ★変更: 職員の分割コントローラーもdispose
    staffLastNameController.dispose();
    staffFirstNameController.dispose();
    staffLastNameKanaController.dispose();
    staffFirstNameKanaController.dispose();
    verificationCodeController.dispose();
    super.dispose();
  }

  // ヘルパーメソッド定義（マスターファイルと同じ位置に配置）
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus && type == TextInputType.phone) {
            final displayFormatted =
                PhoneFormatter.formatPhoneNumberForDisplay(controller.text);

            if (displayFormatted != controller.text) {
              controller.value = TextEditingValue(
                text: displayFormatted,
                selection:
                    TextSelection.collapsed(offset: displayFormatted.length),
              );
            }
          }
        },
        child: TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: type,
          decoration: InputDecoration(
            labelText: label,
            border: const UnderlineInputBorder(),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentPrimary, width: 2),
            ),
          ),
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    VoidCallback? onPressed,
    bool isLoading = false,
    String label = '次へ',
    bool isLineButton = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isLineButton ? const Color(0xFF00B900) : AppColors.textPrimary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white))
            else ...[
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              if (!isLineButton) const SizedBox(width: 8),
              if (!isLineButton) const Icon(Icons.arrow_forward_ios, size: 16),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 24),
        label: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 24),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // メール形式検証
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'メールアドレスを入力してください。';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '正しいメールアドレスを入力してください。';
    }

    return null;
  }

  // 電話番号形式検証
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return '電話番号を入力してください。';
    }

    // 日本電話番号形式チェック
    final phoneRegex = RegExp(r'^0\d{9,10}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[-\s]'), ''))) {
      return '正しい電話番号を入力してください。';
    }

    return null;
  }

  // 電話番号を国際形式に変換 (+81)
  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[-\s]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    return '+81$cleaned';
  }

  // メールアドレス重複チェック
  Future<void> _checkEmailDuplicate() async {
    if (!_emailFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final emailController =
        _role == 'manager' ? managerEmailController : staffEmailController;
    final email = emailController.text.trim();

    try {
      // メール重複確認
      final signInMethods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      // Resumeモードの場合、自分自身のアドレスならOKとする
      final currentUser = FirebaseAuth.instance.currentUser;
      bool isOwnEmail = false;

      if (currentUser != null && currentUser.email == email) {
        isOwnEmail = true;
      }

      // 既にサインイン済みのメソッドがある場合
      if (signInMethods.isNotEmpty) {
        // 自分自身でなければエラー
        if (!isOwnEmail) {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'このメールアドレスは既に使用されています。',
          );
        }
        // 自分自身なら何もしない（通過）
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _nextPage();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'invalid-email') {
          _errorMessage = 'メールアドレスの形式が正しくありません。';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'このメールアドレスは既に使用されています。';
        } else {
          _errorMessage = 'エラーが発生しました: ${e.message}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'エラーが発生しました: $e';
      });
    }
  }

  // アカウント作成 & メール認証リンク送信
  Future<void> _createAccountAndSendEmail() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final emailController =
        _role == 'manager' ? managerEmailController : staffEmailController;
    final passwordController = _role == 'manager'
        ? managerPasswordController
        : staffPasswordController;

    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      setSignUpInProgress(true);

      final currentUser = FirebaseAuth.instance.currentUser;
      final isResume = widget.mode == 'resume' ||
          (currentUser != null && currentUser.email == email);

      // Resumeモードの場合の処理を強化
      if (isResume) {
        User? user = _pendingUser ?? currentUser;

        if (user != null) {
          _pendingUser = user;
          // 既にアカウントがあるので、認証メール送信だけ確認
          if (!user.emailVerified) {
            await user.sendEmailVerification();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('認証メールを送信しました。メールボックスをご確認ください。'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // 既に認証済みなら何もしない
          }
          // ResumeFlowなのでsignOutしない
        } else {
          // Resumeモードなのにユーザーがいない場合、セッション切れとみなして
          // "既に存在する"扱いでログインダイアログへ誘導するために例外を投げる
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'このメールアドレスは既に使用されています。',
          );
        }
      } else {
        // 通常フロー
        // Firebaseアカウント生成
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        _pendingUser = userCredential.user;

        if (_pendingUser == null) {
          throw Exception('アカウント作成に失敗しました。');
        }

        // 認証メール送信
        await _pendingUser!.sendEmailVerification();

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('認証メールを送信しました。メールボックスをご確認ください。'),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      _nextPage();
    } on FirebaseAuthException catch (e) {
      // アカウント生成失敗時
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'email-already-in-use') {
          // _errorMessage = 'このメールアドレスは既に使用されています。';
          // 既に存在する場合、ログインを誘導するダイアログを表示
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('既に登録済みのアドレスです'),
              content: const Text('このメールアドレスは既に登録されています。\nログインして登録を再開しますか？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    context.go('/login'); // Navigate to login
                  },
                  child: const Text('ログインする'),
                ),
              ],
            ),
          );
        } else if (e.code == 'weak-password') {
          _errorMessage = 'パスワードが弱すぎます。';
        } else {
          _errorMessage = 'アカウント作成に失敗しました: ${e.message}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'エラーが発生しました: $e';
      });
    } finally {
      setSignUpInProgress(false);
    }
  }

  // メール認証完了確認
  Future<void> _verifyEmailComplete() async {
    if (_pendingUser == null) {
      setState(() {
        _errorMessage = 'セッションが無効です。最初からやり直してください。';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      setSignUpInProgress(true);

      final emailController =
          _role == 'manager' ? managerEmailController : staffEmailController;
      final passwordController = _role == 'manager'
          ? managerPasswordController
          : staffPasswordController;

      // 再ログイン
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // 使用者情報リロード
      await credential.user?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('ユーザー情報を取得できませんでした。');
      }

      // メール認証状態確認
      if (user.emailVerified) {
        if (widget.mode != 'resume') {
          await FirebaseAuth.instance.signOut();
        }

        if (!mounted) return;

        setState(() {
          _isEmailVerified = true;
          _isLoading = false;
        });

        _nextPage();
      } else {
        if (widget.mode != 'resume') {
          await FirebaseAuth.instance.signOut();
        }

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = 'まだメール認証が完了していません。\nメールの認証リンクをクリックしてから再度お試しください。';
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'user-not-found') {
          _errorMessage = 'アカウントが見つかりません。';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'パスワードが正しくありません。';
        } else {
          _errorMessage = 'メール認証の確認に失敗しました: ${e.message}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'エラーが発生しました: $e';
      });
    } finally {
      setSignUpInProgress(false);
    }
  }

  // メール認証リンク再送信
  Future<void> _resendEmailLink() async {
    if (_pendingUser == null) {
      setState(() {
        _errorMessage = 'セッションが無効です。最初からやり直してください。';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      setSignUpInProgress(true);

      User? user;
      // Resumeモードで既にログイン中なら、再ログインせずにuser取得
      if (widget.mode == 'resume' &&
          FirebaseAuth.instance.currentUser != null) {
        user = FirebaseAuth.instance.currentUser;
      } else {
        final emailController =
            _role == 'manager' ? managerEmailController : staffEmailController;
        final passwordController = _role == 'manager'
            ? managerPasswordController
            : staffPasswordController;

        // 再ログイン
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
        user = credential.user;
      }

      // 認証メール再送信
      await user?.sendEmailVerification();

      if (widget.mode != 'resume') {
        await FirebaseAuth.instance.signOut();
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('認証メールを再送信しました。'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'メールの再送信に失敗しました: $e';
      });
    } finally {
      setSignUpInProgress(false);
    }
  }

  // 電話番号認証コード送信
  Future<void> _sendPhoneCode() async {
    if (!_phoneFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phoneController =
        _role == 'manager' ? managerPhoneController : staffPhoneController;

    // 元データ
    final rawPhoneNumber = phoneController.text.trim();

    final internalNumberString =
        PhoneFormatter.formatPhoneNumberForInternal(rawPhoneNumber);

    // 国際形式に変更
    final phoneNumberForFirebase = _formatPhoneNumber(internalNumberString);

    // テキストフィールド表示用フォーマット更新
    final displayFormatted =
        PhoneFormatter.formatPhoneNumberForDisplay(rawPhoneNumber);
    if (displayFormatted != phoneController.text) {
      phoneController.value = TextEditingValue(
        text: displayFormatted,
        selection: TextSelection.collapsed(offset: displayFormatted.length),
      );
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumberForFirebase,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;
          setState(() {
            _isPhoneVerified = true;
          });
          _nextPage();
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            if (e.code == 'invalid-phone-number') {
              _errorMessage = '電話番号の形式が正しくありません。';
            } else if (e.code == 'too-many-requests') {
              _errorMessage = '試行回数が多すぎます。しばらくしてから再度お試しください。';
            } else {
              _errorMessage = '認証に失敗しました: ${e.message}';
            }
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isLoading = false;
          });
          _nextPage();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
          });
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'エラーが発生しました: $e';
      });
    }
  }

  // 認証コード確認
  Future<void> _verifyPhoneCode() async {
    final code = verificationCodeController.text.trim();

    if (code.isEmpty || code.length != 6) {
      setState(() {
        _errorMessage = '6桁の認証コードを入力してください。';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 会員加入プロセスが進行中であることを通知
    setSignUpInProgress(true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      // 仮ログインプロセス
      await FirebaseAuth.instance.signInWithCredential(credential);
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      setState(() {
        _isPhoneVerified = true;
      });

      _nextPage();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'invalid-verification-code') {
          _errorMessage = '認証コードが正しくありません。';
        } else if (e.code == 'session-expired') {
          _errorMessage = '認証コードの有効期限が切れました。再度送信してください。';
        } else {
          _errorMessage = '認証に失敗しました: ${e.message}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'エラーが発生しました: $e';
      });
    } finally {
      setSignUpInProgress(false);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 認証コード再送信
  Future<void> _resendPhoneCode() async {
    verificationCodeController.clear();
    await _sendPhoneCode();
  }

  Future<void> _handleSignUp() async {
    final internalManagerPhone = PhoneFormatter.formatPhoneNumberForInternal(
        managerPhoneController.text);
    final internalStaffPhone =
        PhoneFormatter.formatPhoneNumberForInternal(staffPhoneController.text);

    // メール認証確認
    if (!_isEmailVerified && widget.mode != 'add_store') {
      setState(() {
        _errorMessage = 'メール認証を完了してください。';
      });
      return;
    }

    // 電話番号認証確認
    if (!_isPhoneVerified && widget.mode != 'add_store') {
      setState(() {
        _errorMessage = '電話番号認証を完了してください。';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final profileService =
        ProviderProfileService(baseUrl: 'https://saboten-server.fly.dev');
    User? newUser;

    try {
      String idToken;
      String firebaseUid;
      final isAddingStore = widget.mode == 'add_store';

      if (!isAddingStore) {
        setSignUpInProgress(true);

        if (!mounted) {
          throw Exception('Widget unmounted before signup');
        }

        final email = _role == 'manager'
            ? managerEmailController.text.trim()
            : staffEmailController.text.trim();

        final password = _role == 'manager'
            ? managerPasswordController.text
            : staffPasswordController.text;

        // 既にアカウントが作成されている為、ログインのみ実施
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        newUser = userCredential.user;
        if (newUser == null) throw Exception('Firebase login failed.');

        // 使用者情報リロード
        await newUser.reload();
        newUser = FirebaseAuth.instance.currentUser;
        if (newUser == null) throw Exception('Failed to reload Firebase user.');

        firebaseUid = newUser.uid;
        final token = await newUser.getIdToken(true);
        if (token == null) {
          throw Exception('Failed to retrieve Firebase ID token.');
        }
        idToken = token;

        if (!mounted) {
          throw Exception('Widget unmounted during signup');
        }
      } else {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw ApiException('ログイン状態が確認できません。');
        }
        firebaseUid = currentUser.uid;
        final token = await currentUser.getIdToken(true);
        if (token == null) {
          throw Exception('Failed to retrieve Firebase ID token.');
        }
        idToken = token;
      }

      late final ProviderProfile profile;
      if (_role == 'manager') {
        // ★変更: 姓・名を結合して送信
        final lastName = managerLastNameController.text.trim();
        final firstName = managerFirstNameController.text.trim();
        final fullName = '$lastName $firstName'.trim();

        // ★★★ 추가: 후리가나를 합칩니다. ★★★
        final lastNameKana = managerLastNameKanaController.text.trim();
        final firstNameKana = managerFirstNameKanaController.text.trim();
        final fullNameFurigana = '$lastNameKana $firstNameKana'.trim();

        // ★追加: デバッグ出力
        // print('======== 管理者名前登録データ ========');
        // print('姓(漢字): $lastName');
        // print('名(漢字): $firstName');
        // print('結合後の名前(漢字): $fullName');
        // print('姓(フリガナ): ${managerLastNameKanaController.text.trim()}');
        // print('名(フリガナ): ${managerFirstNameKanaController.text.trim()}');
        // print(
        //     '結合後の名前(フリガナ): ${managerLastNameKanaController.text.trim()}\u3000${managerFirstNameKanaController.text.trim()}');
        // print('※フリガナは現時点ではサーバに送信されません');
        // print('=====================================');

        profile = ProviderProfile(
          firebaseUid: firebaseUid,
          email: managerEmailController.text.trim(),
          phoneNumber: internalManagerPhone,
          name: fullName,
          nameFurigana: fullNameFurigana,
          role: 'manager',
          storeName: storeNameController.text,
          storeAddress: storeAddressController.text,
          storeTelNumber: storePhoneController.text,
          storeEmail: managerEmailController.text.trim(),
        );
      } else {
        // staff
        final storeExists =
            await profileService.checkStoreExists(staffStoreIdController.text);
        if (!storeExists) throw ApiException('指定された店番号は存在しません');

        // ★変更: 職員も姓・名を結合して送信
        final lastName = staffLastNameController.text.trim();
        final firstName = staffFirstNameController.text.trim();
        final fullName = '$lastName $firstName'.trim();

        final lastNameKana = staffLastNameKanaController.text.trim();
        final firstNameKana = staffFirstNameKanaController.text.trim();
        final fullNameFurigana = '$lastNameKana $firstNameKana'.trim();

        // ★追加: デバッグ出力
        // print('======== 職員名前登録データ ========');
        // print('姓(漢字): $lastName');
        // print('名(漢字): $firstName');
        // print('結合後の名前(漢字): $fullName');
        // print('姓(フリガナ): ${staffLastNameKanaController.text.trim()}');
        // print('名(フリガナ): ${staffFirstNameKanaController.text.trim()}');
        // print(
        //     '結合後の名前(フリガナ): ${staffLastNameKanaController.text.trim()}\u3000${staffFirstNameKanaController.text.trim()}');
        // print('※フリガナは現時点ではサーバに送信されません');
        // print('==================================');

        profile = ProviderProfile(
          firebaseUid: firebaseUid,
          email: staffEmailController.text.trim(),
          phoneNumber: internalStaffPhone,
          name: fullName,
          nameFurigana: fullNameFurigana,
          role: 'staff',
          storeId: staffStoreIdController.text,
        );
      }

      final Map<String, dynamic> createdProfileMap;
      if (isAddingStore) {
        if (_role == 'staff') {
          await profileService.joinStore(staffStoreIdController.text);
          createdProfileMap = {}; // joinStore returns void on success
        } else {
          createdProfileMap =
              await profileService.addNewStore(profile, idToken);
        }
      } else {
        createdProfileMap = await profileService.signUp(profile, idToken);
      }

      if (!mounted) {
        return;
      }

      final profileVM = context.read<ProfileScreenViewModel>();

      if (_role == 'manager') {
        if (isAddingStore) {
          final storeJson = createdProfileMap['store'] as Map<String, dynamic>?;
          if (storeJson != null) {
            final newStoreProfile = StoreProfile.fromJson(storeJson);
            profileVM.addStore(newStoreProfile);
          }
          context.go('/signup-prompt');
        } else {
          final responseData =
              createdProfileMap['data'] as Map<String, dynamic>;
          final userJson = responseData['user'] as Map<String, dynamic>;
          final storeJson = responseData['store'] as Map<String, dynamic>?;
          final newUserProfile = UserProfile.fromJson(userJson);
          final List<StoreProfile> newStores = [];
          if (storeJson != null) {
            newStores.add(StoreProfile.fromJson(storeJson));
          }

          profileVM.setInitialData(newUserProfile, newStores);
          context.go('/signup-prompt');
        }
      } else if (_role == 'staff') {
        if (isAddingStore) {
          // 店舗参加申請成功
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('店舗への参加申請を送信しました。承認をお待ちください。')),
          );
          context.go('/store-selection'); // 店舗選択画面に戻る
        } else {
          // データを再ロード
          await profileVM.loadProfiles();

          if (mounted) {
            context.go('/signup-prompt');
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "エラー : ${e is ApiException ? e.message : e.toString()}";
      });
    } finally {
      setSignUpInProgress(false);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    _pageController.nextPage(
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  // 会員加入戻る確認ダイアログ表示
  Future<bool> _showCancelConfirmDialog() async {
    final result = await showConfirmationDialog(
      context: context,
      title: '登録キャンセル',
      content: '戻ると最初からやり直す必要があります。\n本当に戻りますか？',
      confirmText: 'はい',
    );

    return result ?? false;
  }

  // 戻るボタン処理
  Future<void> _handleBackButton() async {
    if (widget.mode == 'add_store') {
      context.pop();
      return;
    }

    if (_currentPageIndex == 0) {
      context.go('/login');
    } else {
      final shouldGoBack = await _showCancelConfirmDialog();

      if (shouldGoBack && mounted) {
        if (_pendingUser != null) {
          try {
            final email = _role == 'manager'
                ? managerEmailController.text.trim()
                : staffEmailController.text.trim();
            final password = _role == 'manager'
                ? managerPasswordController.text
                : staffPasswordController.text;

            final credential =
                await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            await credential.user?.delete();
          } catch (e) {
            // ユーザー削除失敗時は無視
          }
        }

        if (!mounted) return;

        // ステータス初期化
        setState(() {
          _role = null;
          _isEmailVerified = false;
          _isPhoneVerified = false;
          _pendingUser = null;
          _verificationId = null;
          _errorMessage = null;

          // コントローラー初期化
          managerEmailController.clear();
          managerPasswordController.clear();
          managerConfirmPasswordController.clear();
          managerPhoneController.clear();
          // ★変更: 分割したコントローラーもクリア
          managerLastNameController.clear();
          managerFirstNameController.clear();
          managerLastNameKanaController.clear();
          managerFirstNameKanaController.clear();
          storeNameController.clear();
          storeAddressController.clear();
          storePhoneController.clear();

          staffStoreIdController.clear();
          staffEmailController.clear();
          staffPasswordController.clear();
          staffConfirmPasswordController.clear();
          staffPhoneController.clear();
          // ★変更: 職員の分割コントローラーもクリア
          staffLastNameController.clear();
          staffFirstNameController.clear();
          staffLastNameKanaController.clear();
          staffFirstNameKanaController.clear();

          verificationCodeController.clear();
        });

        // 初ページへ移動
        _pageController.jumpToPage(0);
        _currentPageIndex = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _handleBackButton,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border)),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _buildPages(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPages() {
    if (widget.mode == 'add_store') {
      if (_role == 'staff') {
        return [_buildStaffInfoStep1()];
      }
      return [_buildManagerInfoStep2()];
    }

    if (_role == 'manager') {
      return [
        _buildRoleStep(), // 0: role
        _buildEmailStep(), // 1: email input + 重複確認
        _buildPasswordStep(), // 2: password (アカウント生成 + メール送信)
        _buildEmailVerificationStep(), // 3: email verification waiting
        _buildPhoneNumberStep(), // 4: phone number input
        _buildVerificationCodeStep(), // 5: phone verification code
        _buildManagerInfoStep(), // 6: user info
        _buildManagerInfoStep2(), // 7: store info
      ];
    } else if (_role == 'staff') {
      return [
        _buildRoleStep(), // 0: role
        _buildEmailStep(), // 1: email input + 重複確認
        _buildPasswordStep(), // 2: password password (アカウント生成 + メール送信)
        _buildEmailVerificationStep(), // 3: email verification waiting
        _buildPhoneNumberStep(), // 4: phone number input
        _buildVerificationCodeStep(), // 5: phone verification code
        _buildStaffInfoStep1(), // 6: store number
        _buildStaffInfoStep2(), // 7: user info
      ];
    }
    return [_buildRoleStep()];
  }

  Widget _buildRoleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('アカウント作成',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text('どちらで登録を進めますか？',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        const Spacer(),
        _buildRoleButton(
          label: '管理者として登録',
          icon: Icons.storefront,
          onPressed: () {
            setState(() => _role = 'manager');
            _handleRoleSelection();
          },
        ),
        const SizedBox(height: 16),
        _buildRoleButton(
          label: '職員として登録',
          icon: Icons.person_outline,
          onPressed: () {
            setState(() => _role = 'staff');
            _handleRoleSelection();
          },
        ),
        const Spacer(),
      ],
    );
  }

  // メールアドレス入力画面
  Widget _buildEmailStep() {
    final emailController =
        _role == 'manager' ? managerEmailController : staffEmailController;

    return SingleChildScrollView(
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('メールアドレス認証',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('使用するメールアドレスを入力してください。',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                hintText: 'example@email.com',
                border: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.accentPrimary, width: 2)),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            const Text(
              '※メールアドレスの重複をチェックします',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: AppColors.error)),
              ),
            const SizedBox(height: 40),
            _buildActionButton(
              label: '次へ',
              onPressed: _checkEmailDuplicate,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  // メール認証待機画面
  Widget _buildEmailVerificationStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('メール認証',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('送信されたメールの認証リンクをクリックしてください。',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 48),
          const Icon(Icons.mark_email_read_outlined,
              size: 80, color: AppColors.accentPrimary),
          const SizedBox(height: 32),
          const Text(
            '1. メールボックスを確認\n2. 認証リンクをクリック\n3. アプリに戻って「認証完了」をタップ',
            style: TextStyle(
                fontSize: 15, color: AppColors.textSecondary, height: 1.8),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
              onPressed: _isLoading ? null : _resendEmailLink,
              child: const Text('メールを再送信',
                  style: TextStyle(color: AppColors.accentPrimary))),
          if (_errorMessage != null)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center)),
          const SizedBox(height: 40),
          _buildActionButton(
              label: '認証完了',
              onPressed: _verifyEmailComplete,
              isLoading: _isLoading),
        ],
      ),
    );
  }

  // 電話番号入力画面
  Widget _buildPhoneNumberStep() {
    final phoneController =
        _role == 'manager' ? managerPhoneController : staffPhoneController;

    return SingleChildScrollView(
      child: Form(
        key: _phoneFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('電話番号認証',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('本人確認のために電話番号を認証してください。',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            _buildTextField(
                controller: phoneController,
                label: '電話番号',
                type: TextInputType.phone,
                validator: _validatePhoneNumber),
            const SizedBox(height: 16),
            const Text('※ハイフンなしで入力してください\n※認証コードがSMSで送信されます',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            if (_errorMessage != null)
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: AppColors.error))),
            const SizedBox(height: 40),
            _buildActionButton(
                label: '認証コードを送信',
                onPressed: _sendPhoneCode,
                isLoading: _isLoading),
          ],
        ),
      ),
    );
  }

  void _handleRoleSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = FirebaseAuth.instance.currentUser;

      // 既にログイン済みで、メール未認証の場合は、入力ステップをスキップして認証待機画面へ
      if (currentUser != null && !currentUser.emailVerified) {
        // コントローラーに値をセット（後続の処理で必要なため）
        if (_role == 'manager') {
          managerEmailController.text = currentUser.email ?? '';
        } else {
          staffEmailController.text = currentUser.email ?? '';
        }

        setState(() {
          _pendingUser = currentUser;
        });

        // ページ3（メール認証待機）へジャンプ
        // 0:Role, 1:Email, 2:Pass, 3:Verify
        _pageController.jumpToPage(3);
      } else {
        // 通常フロー
        _nextPage();
      }
    });
  }

  // 認証コード入力画面
  Widget _buildVerificationCodeStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('認証コード入力',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('SMSで送信された6桁のコードを入力してください。',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          TextField(
            controller: verificationCodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: const InputDecoration(
                labelText: '認証コード',
                hintText: '',
                border: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.accentPrimary, width: 2)),
                counterText: ''),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
                onPressed: _isLoading ? null : _resendPhoneCode,
                child: const Text('コードを再送信',
                    style: TextStyle(color: AppColors.accentPrimary))),
          ),
          if (_errorMessage != null)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center)),
          const SizedBox(height: 40),
          _buildActionButton(
              label: '認証', onPressed: _verifyPhoneCode, isLoading: _isLoading),
        ],
      ),
    );
  }

  Widget _buildManagerInfoStep2() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('店舗情報',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('顧客に表示される店舗情報を入力してください。',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          _buildTextField(controller: storeNameController, label: '店名'),
          _buildTextField(controller: storeAddressController, label: '住所'),
          _buildTextField(
            controller: storePhoneController,
            label: '店舗電話番号',
            type: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) return '店舗電話を入力してください。';
              return _validatePhoneNumber(value);
            },
          ),
          if (_errorMessage != null)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center)),
          const SizedBox(height: 60),
          _buildActionButton(
              label: '登録', onPressed: _handleSignUp, isLoading: _isLoading),
        ],
      ),
    );
  }

  Widget _buildStaffInfoStep1() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('店舗番号',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('管理者に共有された店舗番号を入力してください。',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          _buildTextField(controller: staffStoreIdController, label: '店番号'),
          const SizedBox(height: 40),
          _buildActionButton(onPressed: _nextPage),
        ],
      ),
    );
  }

  // ★変更: 職員情報入力画面を姓名分割に対応
  Widget _buildStaffInfoStep2() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('職員情報',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('ログインに使用する情報を入力してください。',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                      controller: staffLastNameController, label: '姓')),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildTextField(
                      controller: staffFirstNameController, label: '名')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                      controller: staffLastNameKanaController,
                      label: 'フリガナ（姓）')),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildTextField(
                      controller: staffFirstNameKanaController,
                      label: 'フリガナ（名）')),
            ],
          ),
          if (_errorMessage != null)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center)),
          const SizedBox(height: 40),
          _buildActionButton(
              label: '登録', onPressed: _handleSignUp, isLoading: _isLoading),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    final passwordController = _role == 'manager'
        ? managerPasswordController
        : staffPasswordController;
    final confirmPasswordController = _role == 'manager'
        ? managerConfirmPasswordController
        : staffConfirmPasswordController;

    void submit() {
      if (_passwordFormKey.currentState!.validate()) {
        // パスワード設定後、すぐにアカウントを作成し、メールを送信
        _createAccountAndSendEmail();
      }
    }

    return SingleChildScrollView(
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('パスワード設定',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('ログインに使用するパスワードを設定してください。',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            _buildTextField(
                controller: passwordController,
                label: 'パスワード',
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'パスワードを入力してください。';
                  if (value.length < 6) return '6文字以上で入力してください。';
                  return null;
                }),
            _buildTextField(
                controller: confirmPasswordController,
                label: 'パスワードの確認',
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'パスワードをもう一度入力してください。';
                  if (value != passwordController.text) return 'パスワードが一致しません。';
                  return null;
                }),
            if (_errorMessage != null)
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: AppColors.error))),
            const SizedBox(height: 40),
            _buildActionButton(onPressed: submit, isLoading: _isLoading),
          ],
        ),
      ),
    );
  }

  // ★変更: 管理者情報入力画面を姓名分割に対応
  Widget _buildManagerInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('管理者情報',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('本人確認のために情報を入力してください。',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                      controller: managerLastNameController, label: '姓')),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildTextField(
                      controller: managerFirstNameController, label: '名')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                      controller: managerLastNameKanaController,
                      label: 'フリガナ（姓）')),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildTextField(
                      controller: managerFirstNameKanaController,
                      label: 'フリガナ（名）')),
            ],
          ),
          const SizedBox(height: 40),
          _buildActionButton(onPressed: _nextPage),
        ],
      ),
    );
  }
}
