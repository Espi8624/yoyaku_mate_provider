import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/constants/privacy_policy.dart';
import 'package:yoyaku_mate_provider/constants/terms_of_service.dart';
import 'package:yoyaku_mate_provider/providers/session_providers.dart';
import 'package:yoyaku_mate_provider/models/user_profile.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/sign_up_providers.dart';
import 'package:yoyaku_mate_provider/routes.dart' show setSignUpInProgress;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/base_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/confirmation_dialog.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/steps/role_selection_step.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/steps/terms_of_service_step.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/steps/privacy_policy_step.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/steps/email_input_step.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/steps/password_input_step.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/steps/email_verification_step.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/steps/phone_number_input_step.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/steps/verification_code_input_step.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/steps/manager_info_step.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/steps/staff_name_step.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  // コントローラー
  final TextEditingController managerEmailController = TextEditingController();
  final TextEditingController managerPasswordController =
      TextEditingController();
  final TextEditingController managerConfirmPasswordController =
      TextEditingController();
  final TextEditingController managerPhoneController = TextEditingController();
  final TextEditingController managerLastNameController =
      TextEditingController();
  final TextEditingController managerFirstNameController =
      TextEditingController();
  final TextEditingController managerLastNameKanaController =
      TextEditingController();
  final TextEditingController managerFirstNameKanaController =
      TextEditingController();

  final TextEditingController staffEmailController = TextEditingController();
  final TextEditingController staffPasswordController = TextEditingController();
  final TextEditingController staffConfirmPasswordController =
      TextEditingController();
  final TextEditingController staffPhoneController = TextEditingController();
  final TextEditingController staffLastNameController = TextEditingController();
  final TextEditingController staffFirstNameController =
      TextEditingController();
  final TextEditingController staffLastNameKanaController =
      TextEditingController();
  final TextEditingController staffFirstNameKanaController =
      TextEditingController();

  final TextEditingController verificationCodeController =
      TextEditingController();

  bool _isInitialized = false;
  ProviderSubscription<AsyncValue<UserProfile>>? _userProfileSubscription;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;

    // userProfileProviderの変化を監視 (build外なのでlistenManualを使用)
    _userProfileSubscription = ref.listenManual(
      userProfileProvider,
      (previous, next) => _populateUserData(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _loadSignUpProgress();
      _populateUserData();
    });

    _pageController.addListener(_pageControllerListener);
  }

  void _populateUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProfile = ref.read(userProfileProvider).valueOrNull;
        final currentUser = FirebaseAuth.instance.currentUser;

        if (userProfile != null) {
          // ユーザープロファイルが存在する場合、Add Storeでない限りサインアップフローにはいないはず
          // しかし、再開のための事前入力などが必要な場合の安全策として維持？
          // Add Store機能は削除されたため、主にFirebaseのcurrentUserに依存して再開する
        } else if (currentUser != null) {
          // 通常フローまたはローカルプロファイルなしのAdd Store
          managerEmailController.text = currentUser.email ?? '';
          staffEmailController.text = currentUser.email ?? '';

          if (currentUser.phoneNumber != null &&
              currentUser.phoneNumber!.isNotEmpty) {
            String phone = currentUser.phoneNumber!;
            if (phone.startsWith('+81')) {
              phone = '0${phone.substring(3)}';
            } else if (phone.startsWith('+82')) {
              phone = '0${phone.substring(3)}';
            }
            managerPhoneController.text = phone;
            staffPhoneController.text = phone;
          } else {
            // フォールバックとしてSharedPreferencesを確認
            SharedPreferences.getInstance().then((prefs) {
              final savedPhone = prefs.getString('signup_phone');
              if (savedPhone != null && mounted) {
                if (managerPhoneController.text.isEmpty) {
                  managerPhoneController.text = savedPhone;
                }
                if (staffPhoneController.text.isEmpty) {
                  staffPhoneController.text = savedPhone;
                }
              }
            });
          }
        }
      }
    });
  }

  Future<void> _loadSignUpProgress() async {
    final targetPage =
        await ref.read(signUpNotifierProvider.notifier).loadSignUpProgress(null);

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 非同期ギャップのためコントローラーを使用する前にmountedを再確認
        if (mounted && _pageController.hasClients) {
          if (_pageController.page?.round() != targetPage) {
            _pageController.jumpToPage(targetPage);
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
    setSignUpInProgress(false);
    _pageController.removeListener(_pageControllerListener);
    _userProfileSubscription?.close();
    _pageController.dispose();

    managerEmailController.dispose();
    managerPasswordController.dispose();
    managerConfirmPasswordController.dispose();
    managerPhoneController.dispose();
    managerLastNameController.dispose();
    managerFirstNameController.dispose();
    managerLastNameKanaController.dispose();
    managerFirstNameKanaController.dispose();

    staffEmailController.dispose();
    staffPasswordController.dispose();
    staffConfirmPasswordController.dispose();
    staffPhoneController.dispose();
    staffLastNameController.dispose();
    staffFirstNameController.dispose();
    staffLastNameKanaController.dispose();
    staffFirstNameKanaController.dispose();

    verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(signUpNotifierProvider); // 再ビルドを監視

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
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
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
    final role = ref.watch(signUpNotifierProvider).role;
    if (role == 'manager') {
      return [
        RoleSelectionStep(onRoleSelected: _handleRoleSelection), // 0
        TermsOfServiceStep(
            onNext: _nextPage, onShowFullTerms: _showTermsDialog), // 1
        PrivacyPolicyStep(
            onNext: _nextPage, onShowFullPolicy: _showPrivacyDialog), // 2
        EmailInputStep(
          controller: managerEmailController,
          onNext: _checkEmailDuplicate,
        ), // 3
        PasswordInputStep(
          passwordController: managerPasswordController,
          confirmPasswordController: managerConfirmPasswordController,
          onNext: _createAccountAndSendEmail,
        ), // 4
        EmailVerificationStep(
          onVerifyComplete: _verifyEmailComplete,
          onResend: _resendEmailLink,
        ), // 5
        PhoneNumberInputStep(
          controller: managerPhoneController,
          onSendCode: _sendPhoneCode,
        ), // 6
        VerificationCodeInputStep(
          controller: verificationCodeController,
          onVerify: _verifyPhoneCode,
          onResend: _resendPhoneCode,
        ), // 7
        ManagerInfoStep(
          lastNameController: managerLastNameController,
          firstNameController: managerFirstNameController,
          lastNameKanaController: managerLastNameKanaController,
          firstNameKanaController: managerFirstNameKanaController,
          onNext: _handleSignUp, // Step 8で完了
        ), // 8
      ];
    } else {
      // スタッフ用ページ
      return [
        RoleSelectionStep(onRoleSelected: _handleRoleSelection), // 0
        TermsOfServiceStep(
            onNext: _nextPage, onShowFullTerms: _showTermsDialog), // 1
        PrivacyPolicyStep(
            onNext: _nextPage, onShowFullPolicy: _showPrivacyDialog), // 2
        EmailInputStep(
          controller: staffEmailController,
          onNext: _checkEmailDuplicate,
        ), // 3
        PasswordInputStep(
          passwordController: staffPasswordController,
          confirmPasswordController: staffConfirmPasswordController,
          onNext: _createAccountAndSendEmail,
        ), // 4
        EmailVerificationStep(
          onVerifyComplete: _verifyEmailComplete,
          onResend: _resendEmailLink,
        ), // 5
        PhoneNumberInputStep(
          controller: staffPhoneController,
          onSendCode: _sendPhoneCode,
        ), // 6
        VerificationCodeInputStep(
          controller: verificationCodeController,
          onVerify: _verifyPhoneCode,
          onResend: _resendPhoneCode,
        ), // 7
        StaffNameStep(
          lastNameController: staffLastNameController,
          firstNameController: staffFirstNameController,
          lastNameKanaController: staffLastNameKanaController,
          firstNameKanaController: staffFirstNameKanaController,
          onSubmit: _handleSignUp, // Step 8で完了
        ), // 8
      ];
    }
  }

  Future<void> _checkEmailDuplicate() async {
    final role = ref.read(signUpNotifierProvider).role;
    final notifier = ref.read(signUpNotifierProvider.notifier);
    final emailController =
        role == 'manager' ? managerEmailController : staffEmailController;
    final email = emailController.text.trim();

    try {
      final success = await notifier.checkEmailDuplicate(email);
      if (success) _nextPage();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'email-already-in-use') {
        showDialog(
          context: context,
          builder: (context) => BaseDialog(
            title: '既に登録済みのアカウントです',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'このメールアドレスは既に登録されています。\nログイン画面に移動しますか？',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/login');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text('ログインする'),
                )
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _createAccountAndSendEmail() async {
    final role = ref.read(signUpNotifierProvider).role;
    final notifier = ref.read(signUpNotifierProvider.notifier);
    final emailController =
        role == 'manager' ? managerEmailController : staffEmailController;
    final passwordController =
        role == 'manager' ? managerPasswordController : staffPasswordController;

    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      final success = await notifier.createAccountAndSendEmail(email, password, '');
      if (success) {
        if (!mounted) return;
        ToastWidget.show(context, '認証メールを送信しました。メールボックスをご確認ください。',
            type: ToastType.success);
        _nextPage();
      }
    } on FirebaseAuthException catch (_) {
      if (!mounted) return;
      // Handle error if needed
    }
  }

  Future<void> _verifyEmailComplete() async {
    final role = ref.read(signUpNotifierProvider).role;
    final notifier = ref.read(signUpNotifierProvider.notifier);
    final emailController =
        role == 'manager' ? managerEmailController : staffEmailController;
    final passwordController =
        role == 'manager' ? managerPasswordController : staffPasswordController;

    final success = await notifier.verifyEmailComplete(
        emailController.text, passwordController.text);
    if (success && mounted) _nextPage();
  }

  Future<void> _resendEmailLink() async {
    final role = ref.read(signUpNotifierProvider).role;
    final notifier = ref.read(signUpNotifierProvider.notifier);
    final emailController =
        role == 'manager' ? managerEmailController : staffEmailController;
    final passwordController =
        role == 'manager' ? managerPasswordController : staffPasswordController;

    final success = await notifier.resendEmailLink(
        emailController.text, passwordController.text, '');
    if (success && mounted) {
      if (success && mounted) {
        ToastWidget.show(context, '認証メールを再送信しました。', type: ToastType.info);
      }
    }
  }

  Future<void> _sendPhoneCode() async {
    final role = ref.read(signUpNotifierProvider).role;
    final notifier = ref.read(signUpNotifierProvider.notifier);
    final phoneController =
        role == 'manager' ? managerPhoneController : staffPhoneController;
    final rawPhoneNumber = phoneController.text.trim();

    final success = await notifier.sendPhoneCode(rawPhoneNumber, role ?? 'manager');
    if (success && mounted) {
      ToastWidget.show(context, '認証コードを送信しました。', type: ToastType.success);
      _nextPage();
    }
  }

  Future<void> _verifyPhoneCode() async {
    final role = ref.read(signUpNotifierProvider).role;
    final notifier = ref.read(signUpNotifierProvider.notifier);
    final success = await notifier.verifyPhoneCode(verificationCodeController.text);
    if (success && mounted) {
      final phoneController =
          role == 'manager' ? managerPhoneController : staffPhoneController;
      notifier.savePhoneProgress(phoneController.text.trim());

      ToastWidget.show(context, '電話番号認証が完了しました。', type: ToastType.success);
      _nextPage();
    }
  }

  Future<void> _resendPhoneCode() async {
    final role = ref.read(signUpNotifierProvider).role;
    final notifier = ref.read(signUpNotifierProvider.notifier);
    final phoneController =
        role == 'manager' ? managerPhoneController : staffPhoneController;
    final success =
        await notifier.sendPhoneCode(phoneController.text.trim(), role ?? 'manager');
    if (success && mounted) {
      if (success && mounted) {
        ToastWidget.show(context, '認証コードを再送信しました。', type: ToastType.success);
      }
    }
  }

  Future<void> _handleSignUp() async {
    final notifier = ref.read(signUpNotifierProvider.notifier);

    final managerName =
        '${managerLastNameController.text.trim()} ${managerFirstNameController.text.trim()}';
    final managerNameKana =
        '${managerLastNameKanaController.text.trim()} ${managerFirstNameKanaController.text.trim()}';
    final staffName =
        '${staffLastNameController.text.trim()} ${staffFirstNameController.text.trim()}';
    final staffNameKana =
        '${staffLastNameKanaController.text.trim()} ${staffFirstNameKanaController.text.trim()}';

    // Refactor: Pass null/empty for store fields
    final success = await notifier.handleSignUp(
      mode: null,
      managerName: managerName,
      managerNameKana: managerNameKana,
      storeName: null,
      storeAddress: null,
      storeZipCode: null,
      storePrefecture: null,
      storeCity: null,
      storeBuilding: null,
      storePhone: null,
      staffName: staffName,
      staffNameKana: staffNameKana,
      staffStoreId: null, // 店舗IDなし
      managerPhoneInput: managerPhoneController.text.trim(),
      staffPhoneInput: staffPhoneController.text.trim(),
      // Default values
      estimatedWaitTime: 10,
      maxWaitingCount: 10,
      isPreOrderEnabled: false,
      requireOneMenuPerPerson: false,
    );

    if (success && mounted) {
      // 登録完了後、グローバルなプロフィール情報を更新してから遷移
      ref.invalidate(userProfileProvider);
      ref.invalidate(myStoresProvider);
      await Future.wait([
        ref.read(userProfileProvider.future),
        ref.read(myStoresProvider.future),
      ]);
      if (mounted) {
        // Refactor: 登録完了画面 または ホームへ (main.dart route logic will redirect to StoreSelection)
        // ここでは一旦完了画面へ
        context.go('/signup-prompt');
      }
    }
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    final currentUser = FirebaseAuth.instance.currentUser;
    int nextIndex = _currentPageIndex + 1;

    // Refactor: StoreWizard skip logic removed

    if (currentUser != null) {
      final isEmailVerified = ref.read(signUpNotifierProvider).isEmailVerified;
      if (_currentPageIndex == 2) {
        // プライバシー -> メール
        if (isEmailVerified) {
          nextIndex = 6; // Phone
        } else {
          nextIndex = 5; // メール認証待機
        }
      } else if (_currentPageIndex == 5 && isEmailVerified) {
        nextIndex = 6; // Phone
      }
    }

    _pageController.animateToPage(nextIndex,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _handleRoleSelection() {
    ref.read(signUpNotifierProvider.notifier).saveSignUpProgress();
    _nextPage();
  }

  Future<void> _handleBackButton() async {
    if (_currentPageIndex == 0) {
      context.go('/login');
    } else {
      final shouldGoBack = await _showCancelConfirmDialog();
      if (shouldGoBack && mounted) {
        ref.read(signUpNotifierProvider.notifier).reset();

        managerEmailController.clear();
        managerPasswordController.clear();
        managerConfirmPasswordController.clear();
        managerPhoneController.clear();
        managerLastNameController.clear();
        managerFirstNameController.clear();
        managerLastNameKanaController.clear();
        managerFirstNameKanaController.clear();

        staffEmailController.clear();
        staffPasswordController.clear();
        staffConfirmPasswordController.clear();
        staffPhoneController.clear();
        staffLastNameController.clear();
        staffFirstNameController.clear();
        staffLastNameKanaController.clear();
        staffFirstNameKanaController.clear();
        verificationCodeController.clear();

        _pageController.jumpToPage(0);
      }
    }
  }

  Future<bool> _showCancelConfirmDialog() async {
    final result = await showConfirmationDialog(
      context: context,
      title: '登録キャンセル',
      content: '戻ると最初からやり直す必要があります。\n本当に戻りますか？',
      confirmText: 'はい',
    );
    return result ?? false;
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => const BaseDialog(
        title: '利用規約',
        content: Text(TermsOfService.content),
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => const BaseDialog(
        title: 'プライバシーポリシー',
        content: Text(PrivacyPolicy.content),
      ),
    );
  }
}
