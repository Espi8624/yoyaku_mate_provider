import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/constants/privacy_policy.dart';
import 'package:yoyaku_mate_provider/constants/terms_of_service.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen_viewmodel.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/sign_up_viewmodel.dart';
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
import 'package:yoyaku_mate_provider/pages/sign_up/steps/store_wizard_steps.dart'; // New Import
import 'package:yoyaku_mate_provider/pages/sign_up/steps/store_business_hours_step.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/steps/staff_store_id_step.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/steps/staff_name_step.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  // Controllers
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

  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController storeAddressController = TextEditingController();
  final TextEditingController storePhoneController = TextEditingController();
  final TextEditingController estimatedWaitTimeController =
      TextEditingController(text: '10');
  final TextEditingController maxWaitingCountController =
      TextEditingController(text: '10');
  bool _enableMenuSelection = false;

  final TextEditingController staffStoreIdController = TextEditingController();
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
  ProfileScreenViewModel? _profileVM;

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

    final vm = context.read<SignUpViewModel>();

    // Cache the view models here to ensure they are available
    _profileVM = context.read<ProfileScreenViewModel>();
    _profileVM?.addListener(_populateUserData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _loadSignUpProgress(vm);
      _populateUserData();
    });

    _pageController.addListener(_pageControllerListener);
  }

  void _populateUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final profileVM = _profileVM;
        // Check if profileVM is effectively available
        if (profileVM == null) return;

        final userProfile = profileVM.userProfile;
        final currentUser = FirebaseAuth.instance.currentUser;

        if (userProfile != null) {
          // If user profile exists, they shouldn't be in sign up flow unless it was add_store which is removed.
          // However, keeping safe fallback or if we need to pre-fill from profile for restart?
          // Since add_store is gone, likely we rely on currentUser (Firebase) primarily for fresh sign up resume.
          // We'll remove the userProfile specific block as it was mainly for Add Store.
        } else if (currentUser != null) {
          // Regular flow or add_store with no local profile yet
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
            // Check SharedPreferences as fallback
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

  Future<void> _loadSignUpProgress(SignUpViewModel vm) async {
    final targetPage = await vm.loadSignUpProgress(null);

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check mounted again before using controller because of async gap
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
    _profileVM?.removeListener(_populateUserData);
    _pageController.dispose();

    managerEmailController.dispose();
    managerPasswordController.dispose();
    managerConfirmPasswordController.dispose();
    managerPhoneController.dispose();
    managerLastNameController.dispose();
    managerFirstNameController.dispose();
    managerLastNameKanaController.dispose();
    managerFirstNameKanaController.dispose();

    storeNameController.dispose();
    storeAddressController.dispose();
    storePhoneController.dispose();
    estimatedWaitTimeController.dispose();
    maxWaitingCountController.dispose();

    staffStoreIdController.dispose();
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
    context.watch<SignUpViewModel>(); // Watch for rebuilds

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
    final role = context.watch<SignUpViewModel>().role;
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
          onNext: _nextPage,
        ), // 8
        StoreBasicInfoStep(
          nameController: storeNameController,
          addressController: storeAddressController,
          phoneController: storePhoneController,
          onNext: _nextPage,
        ), // 9
        StoreCapacityStep(
          maxWaitingCountController: maxWaitingCountController,
          onNext: _nextPage,
        ), // 10
        StoreBusinessHoursStep(
          onNext: _handleBusinessHours,
        ), // 11
        StoreTimeStep(
          estimatedWaitTimeController: estimatedWaitTimeController,
          onNext: _nextPage,
        ), // 12
        StorePreOrderStep(
          isPreOrderEnabled: _enableMenuSelection,
          onPreOrderChanged: (value) {
            setState(() {
              _enableMenuSelection = value;
            });
          },
          onNext: _nextPage,
        ), // 13
        StoreReviewStep(
          nameController: storeNameController,
          addressController: storeAddressController,
          phoneController: storePhoneController,
          maxWaitingCountController: maxWaitingCountController,
          estimatedWaitTimeController: estimatedWaitTimeController,
          isPreOrderEnabled: _enableMenuSelection,
          onSubmit: _handleSignUp,
          isLoading: context.read<SignUpViewModel>().isLoading,
        ), // 13
      ];
    } else {
      // Staff pages
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
        StaffStoreIdStep(
          storeIdController: staffStoreIdController,
          onNext: _nextPage,
        ), // 8 (Store ID)
        StaffNameStep(
          lastNameController: staffLastNameController,
          firstNameController: staffFirstNameController,
          lastNameKanaController: staffLastNameKanaController,
          firstNameKanaController: staffFirstNameKanaController,
          onSubmit: _handleSignUp,
        ), // 9 (Name)
      ];
    }
  }

  Future<void> _checkEmailDuplicate() async {
    final vm = context.read<SignUpViewModel>();
    final emailController =
        vm.role == 'manager' ? managerEmailController : staffEmailController;
    final email = emailController.text.trim();

    try {
      final success = await vm.checkEmailDuplicate(email);
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
    final vm = context.read<SignUpViewModel>();
    final emailController =
        vm.role == 'manager' ? managerEmailController : staffEmailController;
    final passwordController = vm.role == 'manager'
        ? managerPasswordController
        : staffPasswordController;

    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      final success = await vm.createAccountAndSendEmail(email, password, '');
      if (success) {
        if (!mounted) return;
        if (!mounted) return;
        ToastWidget.show(context, '認証メールを送信しました。メールボックスをご確認ください。',
            type: ToastType.success);
        _nextPage();
        _nextPage();
      }
    } on FirebaseAuthException catch (_) {
      if (!mounted) return;
      // Handle error if needed
    }
  }

  Future<void> _verifyEmailComplete() async {
    final vm = context.read<SignUpViewModel>();
    final emailController =
        vm.role == 'manager' ? managerEmailController : staffEmailController;
    final passwordController = vm.role == 'manager'
        ? managerPasswordController
        : staffPasswordController;

    final success = await vm.verifyEmailComplete(
        emailController.text, passwordController.text);
    if (success && mounted) _nextPage();
  }

  Future<void> _resendEmailLink() async {
    final vm = context.read<SignUpViewModel>();
    final emailController =
        vm.role == 'manager' ? managerEmailController : staffEmailController;
    final passwordController = vm.role == 'manager'
        ? managerPasswordController
        : staffPasswordController;

    final success = await vm.resendEmailLink(
        emailController.text, passwordController.text, '');
    if (success && mounted) {
      if (success && mounted) {
        ToastWidget.show(context, '認証メールを再送信しました。', type: ToastType.info);
      }
    }
  }

  Future<void> _sendPhoneCode() async {
    final vm = context.read<SignUpViewModel>();
    final phoneController =
        vm.role == 'manager' ? managerPhoneController : staffPhoneController;
    final rawPhoneNumber = phoneController.text.trim();

    final success =
        await vm.sendPhoneCode(rawPhoneNumber, vm.role ?? 'manager');
    if (success && mounted) {
      if (success && mounted) {
        ToastWidget.show(context, '認証コードを送信しました。', type: ToastType.success);
        _nextPage();
        _nextPage();
      }
    }
  }

  Future<void> _verifyPhoneCode() async {
    final vm = context.read<SignUpViewModel>();
    final success = await vm.verifyPhoneCode(verificationCodeController.text);
    if (success && mounted) {
      final phoneController =
          vm.role == 'manager' ? managerPhoneController : staffPhoneController;
      vm.savePhoneProgress(phoneController.text.trim());

      vm.savePhoneProgress(phoneController.text.trim());

      ToastWidget.show(context, '電話番号認証が完了しました。', type: ToastType.success);
      _nextPage();
      _nextPage();
    }
  }

  Future<void> _resendPhoneCode() async {
    final vm = context.read<SignUpViewModel>();
    final phoneController =
        vm.role == 'manager' ? managerPhoneController : staffPhoneController;
    final success = await vm.sendPhoneCode(
        phoneController.text.trim(), vm.role ?? 'manager');
    if (success && mounted) {
      if (success && mounted) {
        ToastWidget.show(context, '認証コードを再送信しました。', type: ToastType.success);
      }
    }
  }

  Future<void> _handleSignUp() async {
    final vm = context.read<SignUpViewModel>();

    final managerName =
        '${managerLastNameController.text.trim()} ${managerFirstNameController.text.trim()}';
    final managerNameKana =
        '${managerLastNameKanaController.text.trim()} ${managerFirstNameKanaController.text.trim()}';
    final staffName =
        '${staffLastNameController.text.trim()} ${staffFirstNameController.text.trim()}';
    final staffNameKana =
        '${staffLastNameKanaController.text.trim()} ${staffFirstNameKanaController.text.trim()}';

    final success = await vm.handleSignUp(
      mode: null,
      managerName: managerName,
      managerNameKana: managerNameKana,
      storeName: storeNameController.text.trim(),
      storeAddress: storeAddressController.text.trim(),
      storePhone: storePhoneController.text.trim(),
      staffName: staffName,
      staffNameKana: staffNameKana,
      staffStoreId: staffStoreIdController.text.trim(),
      managerPhoneInput: managerPhoneController.text.trim(),
      staffPhoneInput: staffPhoneController.text.trim(),
      estimatedWaitTime: int.tryParse(estimatedWaitTimeController.text) ?? 10,
      maxWaitingCount: int.tryParse(maxWaitingCountController.text) ?? 10,
      isPreOrderEnabled: _enableMenuSelection,
    );

    if (success && mounted) {
      // 登録完了後、グローバルなプロフィール情報を更新してから遷移
      await context.read<ProfileScreenViewModel>().loadProfiles();
      if (mounted) {
        context.go('/signup-prompt');
      }
    }
  }

  void _handleBusinessHours(
      Map<String, Map<String, String>> hours, bool is24h, String resetTime) {
    context.read<SignUpViewModel>().saveBusinessHours(hours, is24h, resetTime);
    _nextPage();
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    final currentUser = FirebaseAuth.instance.currentUser;
    int nextIndex = _currentPageIndex + 1;

    if (currentUser != null) {
      if (_currentPageIndex == 2) {
        // Privacy -> Email
        final isEmailVerified = context.read<SignUpViewModel>().isEmailVerified;
        if (isEmailVerified) {
          nextIndex = 6; // Phone
        } else {
          nextIndex = 5; // Email Verify Wait
        }
      } else if (_currentPageIndex == 5 &&
          context.read<SignUpViewModel>().isEmailVerified) {
        nextIndex = 6; // Phone
      }
    }

    _pageController.animateToPage(nextIndex,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _handleRoleSelection() {
    context.read<SignUpViewModel>().saveSignUpProgress();
    _nextPage();
  }

  Future<void> _handleBackButton() async {
    if (_currentPageIndex == 0) {
      context.go('/login');
    } else {
      final shouldGoBack = await _showCancelConfirmDialog();
      if (shouldGoBack && mounted) {
        context.read<SignUpViewModel>().reset();

        managerEmailController.clear();
        managerPasswordController.clear();
        managerConfirmPasswordController.clear();
        managerPhoneController.clear();
        managerLastNameController.clear();
        managerFirstNameController.clear();
        managerLastNameKanaController.clear();
        managerFirstNameKanaController.clear();
        storeNameController.clear();
        storeAddressController.clear();
        storePhoneController.clear();
        estimatedWaitTimeController.text = '10';
        maxWaitingCountController.text = '10';
        _enableMenuSelection = false;
        staffStoreIdController.clear();
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
