// import 'dart:io';
// import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/models/provider_profile.dart';
import 'package:yoyaku_mate_provider/models/store_profile.dart';
import 'package:yoyaku_mate_provider/models/user_profile.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen_viewmodel.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';

import 'package:yoyaku_mate_provider/routes.dart' show setSignUpInProgress;

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
  // String? _lineLoginUrl;

  late PageController _pageController;
  int _currentPageIndex = 0;

  // bool _isEmailVerified = false;

  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  // コントローラー初期化
  final TextEditingController managerEmailController = TextEditingController();
  final TextEditingController managerPasswordController =
      TextEditingController();
  final TextEditingController managerConfirmPasswordController =
      TextEditingController();
  final TextEditingController managerPhoneController = TextEditingController();
  final TextEditingController managerNameController = TextEditingController();
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController storeAddressController = TextEditingController();
  final TextEditingController storePhoneController = TextEditingController();

  final TextEditingController staffStoreIdController = TextEditingController();
  final TextEditingController staffEmailController = TextEditingController();
  final TextEditingController staffPasswordController = TextEditingController();
  final TextEditingController staffConfirmPasswordController =
      TextEditingController();
  final TextEditingController staffPhoneController = TextEditingController();
  final TextEditingController staffNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    int initialPage = 0;
    if (widget.mode == 'add_store') {
      _role = 'manager';
      initialPage = 4; // 店舗情報入力index
    }

    _pageController = PageController(initialPage: initialPage);

    _pageController.addListener(() {
      if (!mounted) return;
      final newPage = _pageController.page?.round();
      if (newPage != null && newPage != _currentPageIndex) {
        setState(() {
          _currentPageIndex = newPage;
        });
      }
    });

    if (widget.mode == 'add_store') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final profileVM = context.read<ProfileScreenViewModel>();
          final userProfile = profileVM.userProfile;

          if (userProfile != null) {
            managerEmailController.text = userProfile.email;
            managerPhoneController.text = userProfile.phone;
            managerNameController.text = userProfile.name;
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

  @override
  void dispose() {
    _pageController.dispose();
    managerEmailController.dispose();
    managerPasswordController.dispose();
    managerConfirmPasswordController.dispose();
    managerPhoneController.dispose();
    managerNameController.dispose();
    storeNameController.dispose();
    storeAddressController.dispose();
    storePhoneController.dispose();
    staffStoreIdController.dispose();
    staffEmailController.dispose();
    staffPasswordController.dispose();
    staffConfirmPasswordController.dispose();
    staffPhoneController.dispose();
    staffNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final profileService =
        ProviderProfileService(baseUrl: 'http://10.0.2.2:8080');
    User? newUser;

    try {
      String idToken;
      String firebaseUid;
      final isAddingStore = widget.mode == 'add_store';

      if (!isAddingStore) {
        setSignUpInProgress(true);

        // print("--- [SignUpPage] Firebase 계정 생성 전, 플래그 미리 설정 ---");
        if (!mounted) {
          throw Exception('Widget unmounted before signup');
        }

        final profileVM = context.read<ProfileScreenViewModel>();
        profileVM.prepareForSignUp();
        // print("--- [SignUpPage] prepareForSignUp() 호출 완료 (계정 생성 전) ---");

        // 이제 Firebase 계정 생성
        final email = _role == 'manager'
            ? managerEmailController.text.trim()
            : staffEmailController.text.trim();

        final password = _role == 'manager'
            ? managerPasswordController.text
            : staffPasswordController.text;

        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        newUser = userCredential.user;
        if (newUser == null) throw Exception('Firebase user creation failed.');

        // email認証
        try {
          await newUser.sendEmailVerification();
        } catch (e) {
          print('Failed to send verification email: $e');
        }

        await newUser.reload();
        newUser = FirebaseAuth.instance.currentUser;
        if (newUser == null) throw Exception('Failed to reload Firebase user.');

        firebaseUid = newUser.uid;
        final token = await newUser.getIdToken(true);
        if (token == null)
          throw Exception('Failed to retrieve Firebase ID token.');
        idToken = token;

        // print("--- [SignUpPage] Firebase 계정 생성 완료 ---");

        if (!mounted) {
          // print("[SignUpPage] Widget unmounted after Firebase creation");
          throw Exception('Widget unmounted during signup');
        }
      } else {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) throw ApiException('ログイン状態が確認できません。');
        firebaseUid = currentUser.uid;
        final token = await currentUser.getIdToken(true);
        if (token == null)
          throw Exception('Failed to retrieve Firebase ID token.');
        idToken = token;
      }

      late final ProviderProfile profile;
      if (_role == 'manager') {
        profile = ProviderProfile(
          firebaseUid: firebaseUid,
          email: managerEmailController.text.trim(),
          phoneNumber: managerPhoneController.text,
          name: managerNameController.text,
          role: 'manager',
          storeName: storeNameController.text,
          storeAddress: storeAddressController.text,
          storeTelNumber: storePhoneController.text,
          storeEmail: managerEmailController.text.trim(),
        );
      } else {
        final storeExists =
            await profileService.checkStoreExists(staffStoreIdController.text);
        if (!storeExists) throw ApiException('指定された店番号は存在しません');
        profile = ProviderProfile(
          firebaseUid: firebaseUid,
          email: staffEmailController.text.trim(),
          phoneNumber: staffPhoneController.text,
          name: staffNameController.text,
          role: 'staff',
          storeId: staffStoreIdController.text,
        );
      }

      final Map<String, dynamic> createdProfileMap = isAddingStore
          ? await profileService.addNewStore(profile, idToken)
          : await profileService.signUp(profile, idToken);

      // print("--- [SignUpPage] 백엔드로부터 받은 원본 응답 ---");
      // print(createdProfileMap);

      if (!mounted) {
        // print("[SignUpPage] Widget unmounted after backend response");
        return;
      }

      final responseData = createdProfileMap['data'] as Map<String, dynamic>;
      final userJson = responseData['user'] as Map<String, dynamic>;
      final profileVM = context.read<ProfileScreenViewModel>();

      // print("--- [SignUpPage] 데이터 주입 시도 ---");
      // print("  - 현재 ViewModel 인스턴스 해시코드: ${profileVM.hashCode}");
      // print("  - isAddingStore: $isAddingStore");

      if (_role == 'manager') {
        // 店舗追加パターン
        if (isAddingStore) {
          final storeJson = responseData['store'] as Map<String, dynamic>?;
          if (storeJson != null) {
            final newStoreProfile = StoreProfile.fromJson(storeJson);
            profileVM.addStore(newStoreProfile);
          }
          context.go('/signup-prompt');
        } else {
          // 新規登録パターン
          final storeJson = responseData['store'] as Map<String, dynamic>?;
          final newUserProfile = UserProfile.fromJson(userJson);
          final List<StoreProfile> newStores = [];
          if (storeJson != null) {
            newStores.add(StoreProfile.fromJson(storeJson));
          }

          profileVM.setInitialData(newUserProfile, newStores);
          context.go('/signup-prompt');
        }
      }
    } catch (e) {
      if (widget.mode != 'add_store' && newUser != null) {
        await newUser.delete();
      }
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

  // Future<void> _launchLineLogin() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     if (_lineLoginUrl == null)
  //       throw Exception('LINE Login URL is not available.');
  //     final Uri url = Uri.parse(_lineLoginUrl!);

  //     if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
  //       throw Exception('Could not launch the URL.');
  //     }

  //     if (widget.mode != 'add_store') {
  //       if (mounted) {
  //         context.go('/signup-prompt');
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() {
  //         _errorMessage = 'LINEを開けません。アプリが設置されているか確認をお願いします。';
  //       });
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  // }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    _pageController.nextPage(
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    if (_currentPageIndex == 1) {
      setState(() {
        _role = null;
      });
    }
    _pageController.previousPage(
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final isAddStoreMode = widget.mode == 'add_store';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  if (isAddStoreMode) {
                    context.pop();
                    return;
                  }

                  if (_currentPageIndex == 0) {
                    context.go('/login');
                  } else {
                    _previousPage();
                  }
                },
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
      return [_buildManagerInfoStep2()];
    }

    if (_role == 'manager') {
      return [
        _buildRoleStep(), // 0: role
        _buildEmailStep(), // 1: email
        _buildPasswordStep(), // 2: password
        _buildManagerInfoStep(), // 3: user info
        _buildManagerInfoStep2(), // 4: store info
      ];
    } else if (_role == 'staff') {
      return [
        _buildRoleStep(), // 0: role
        _buildEmailStep(), // 1: email
        _buildPasswordStep(), // 2: password
        _buildStaffInfoStep1(), // 3: store number
        _buildStaffInfoStep2(), // 4: user info
      ];
    }
    return [_buildRoleStep()]; // role選択前
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
            WidgetsBinding.instance.addPostFrameCallback((_) => _nextPage());
          },
        ),
        const SizedBox(height: 16),
        _buildRoleButton(
          label: '職員として登録',
          icon: Icons.person_outline,
          onPressed: () {
            setState(() => _role = 'staff');
            WidgetsBinding.instance.addPostFrameCallback((_) => _nextPage());
          },
        ),
        const Spacer(),
      ],
    );
  }

  // Widget _buildManagerInfoStep1() {
  //   return SingleChildScrollView(
  //     keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text('管理者情報',
  //             style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
  //         const SizedBox(height: 8),
  //         const Text('ログイン及び本人確認のために情報を入力してください。',
  //             style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
  //         const SizedBox(height: 32),
  //         _buildTextField(
  //             controller: managerEmailController,
  //             label: 'メールアドレス',
  //             type: TextInputType.emailAddress),
  //         _buildTextField(
  //             controller: managerPasswordController,
  //             label: 'パスワード',
  //             isPassword: true),
  //         _buildTextField(
  //             controller: managerPhoneController,
  //             label: '電話番号',
  //             type: TextInputType.phone),
  //         _buildTextField(controller: managerNameController, label: '名前'),
  //         const SizedBox(height: 40),
  //         _buildActionButton(onPressed: _nextPage),
  //       ],
  //     ),
  //   );
  // }

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
              type: TextInputType.phone),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center),
            ),
          const SizedBox(height: 60),
          _buildActionButton(
            label: '登録',
            onPressed: _handleSignUp,
            isLoading: _isLoading,
          ),
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
          _buildTextField(
              controller: staffEmailController,
              label: 'メールアドレス',
              type: TextInputType.emailAddress),
          _buildTextField(
              controller: staffPasswordController,
              label: 'パスワード',
              isPassword: true),
          _buildTextField(
              controller: staffPhoneController,
              label: '電話番号',
              type: TextInputType.phone),
          _buildTextField(controller: staffNameController, label: '名前'),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center),
            ),
          const SizedBox(height: 40),
          _buildActionButton(
            label: '登録',
            onPressed: _handleSignUp,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    final emailController =
        _role == 'manager' ? managerEmailController : staffEmailController;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('メールアドレス認証',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('まず、使用するメールアドレスを認証してください。',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'メールアドレス'),
        ),
        const Spacer(),
        _buildActionButton(onPressed: _nextPage),
      ],
    );
  }

  Widget _buildPasswordStep() {
    final passwordController = _role == 'manager'
        ? managerPasswordController
        : staffPasswordController;
    final confirmPasswordController = _role == 'manager'
        ? managerConfirmPasswordController
        : staffConfirmPasswordController;

    // 次へボタン押下時実行
    void submit() {
      if (_passwordFormKey.currentState!.validate()) {
        _nextPage();
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
              // 有効性検査機(validator)追加
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'パスワードを入力してください。';
                }
                if (value.length < 6) {
                  return '6文字以上で入力してください。';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: confirmPasswordController,
              label: 'パスワードの確認',
              isPassword: true,
              // 有効性検査機(validator)追加
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'パスワードをもう一度入力してください。';
                }
                if (value != passwordController.text) {
                  return 'パスワードが一致しません。';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),
            _buildActionButton(onPressed: submit),
          ],
        ),
      ),
    );
  }

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
          _buildTextField(
              controller: managerPhoneController,
              label: '電話番号',
              type: TextInputType.phone),
          _buildTextField(controller: managerNameController, label: '名前'),
          const SizedBox(height: 40),
          _buildActionButton(onPressed: _nextPage),
        ],
      ),
    );
  }

  // Widget _buildLineIntegrationStep() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.center,
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       const Spacer(),
  //       const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
  //       const SizedBox(height: 24),
  //       const Text('申請が仮受付されました。',
  //           style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
  //           textAlign: TextAlign.center),
  //       const SizedBox(height: 16),
  //       const Text(
  //           '最後に、ご本人確認のためにLINEアカウントを連携してください。下のボタンを押して、LINEで申請を完了してください。',
  //           style: TextStyle(
  //               fontSize: 15, color: AppColors.textSecondary, height: 1.5),
  //           textAlign: TextAlign.center),
  //       const Spacer(),
  //       _buildActionButton(
  //         label: 'LINEで申請完了',
  //         onPressed: () {
  //           if (!_isLoading) {
  //             _launchLineLogin();
  //           }
  //         },
  //         isLoading: _isLoading,
  //         isLineButton: true,
  //       ),
  //       const SizedBox(height: 16),
  //     ],
  //   );
  // }

  Widget _buildRoleButton(
      {required String label,
      required IconData icon,
      required VoidCallback onPressed}) {
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const UnderlineInputBorder(),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentPrimary, width: 2)),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildActionButton(
      {VoidCallback? onPressed,
      bool isLoading = false,
      String label = '次へ',
      bool isLineButton = false}) {
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
}
