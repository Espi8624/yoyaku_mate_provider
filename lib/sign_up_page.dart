import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/models/provider_profile.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen_viewmodel.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/custom_snack_bar.dart';

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
  String? _lineLoginUrl;
  File? _licenseImageFile;
  final ImagePicker _picker = ImagePicker();

  late PageController _pageController;
  int _currentPageIndex = 0;

  // コントローラー初期化
  final TextEditingController managerEmailController = TextEditingController();
  final TextEditingController managerPasswordController =
      TextEditingController();
  final TextEditingController managerPhoneController = TextEditingController();
  final TextEditingController managerNameController = TextEditingController();
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController storeAddressController = TextEditingController();
  final TextEditingController storePhoneController = TextEditingController();

  final TextEditingController staffStoreIdController = TextEditingController();
  final TextEditingController staffEmailController = TextEditingController();
  final TextEditingController staffPasswordController = TextEditingController();
  final TextEditingController staffPhoneController = TextEditingController();
  final TextEditingController staffNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 基本デフォルトページは0
    int initialPage = 0;

    // 店舗追加モードかを確認し、初期状態を設定
    if (widget.mode == 'add_store') {
      _role = 'manager';
      initialPage = 2;
    }

    // 計算されたinitialPageでPageControllerを生成
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
    managerPhoneController.dispose();
    managerNameController.dispose();
    storeNameController.dispose();
    storeAddressController.dispose();
    storePhoneController.dispose();
    staffStoreIdController.dispose();
    staffEmailController.dispose();
    staffPasswordController.dispose();
    staffPhoneController.dispose();
    staffNameController.dispose();
    super.dispose();
  }

  // イメージ選択する関数
  Future<void> _pickImage() async {
    try {
      File? selectedFile;
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        final result = await FilePicker.platform
            .pickFiles(type: FileType.image, allowMultiple: false);
        if (result != null && result.files.single.path != null) {
          selectedFile = File(result.files.single.path!);
        }
      } else {
        final XFile? pickedFile =
            await _picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          selectedFile = File(pickedFile.path);
        }
      }
      if (selectedFile != null) {
        setState(() {
          _licenseImageFile = selectedFile;
          _errorMessage = null; // エラーメッセージをクリア
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "イメージ選択中にエラー発生: $e";
        });
      }
    }
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

      // 認証処理
      if (isAddingStore) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) throw ApiException('ログイン状態が確認できません。');
        firebaseUid = currentUser.uid;
        final token = await currentUser.getIdToken(true);
        if (token == null)
          throw Exception('Failed to retrieve Firebase ID token.');
        idToken = token;
      } else {
        // 新規加入
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
        firebaseUid = newUser.uid;
        final token = await newUser.getIdToken(true);
        if (token == null)
          throw Exception('Failed to retrieve Firebase ID token.');
        idToken = token;
      }

      // プロフィール情報構築
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
        // staff
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

      // Backendにプロフィール情報を送信
      final Map<String, dynamic> createdProfileMap;

      if (isAddingStore) {
        // 店舗追加モード
        createdProfileMap = await profileService.addNewStore(profile, idToken);
      } else {
        // 新規加入モード
        createdProfileMap = await profileService.signUp(profile, idToken);
      }

      final userData = createdProfileMap['data'] as Map<String, dynamic>? ?? {};
      final storeId = userData['store_id'] as String?;
      _lineLoginUrl = userData['line_login_url'] as String?;

      if (_role == 'manager') {
        if (_licenseImageFile != null && storeId != null) {
          await profileService.uploadLicenseImage(storeId, _licenseImageFile!);
        }
        if (_lineLoginUrl == null || _lineLoginUrl!.isEmpty) {
          throw ApiException('LINE連携URLの取得に失敗しました。');
        }
        _nextPage();
      } else {
        // staff
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          CustomSnackBar.show(context,
              message: '会員登録が完了しました。ログインしてください',
              status: SnackBarStatus.success);
          context.go('/login');
        }
      }
    } catch (e) {
      // 新規加入に失敗した場合にのみ、作成されたユーザーを削除
      if (widget.mode != 'add_store' && newUser != null) {
        await newUser.delete();
      }
      if (mounted) {
        setState(() {
          _errorMessage =
              "エラー : ${e is ApiException ? e.message : e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchLineLogin() async {
    setState(() => _isLoading = true);
    try {
      if (_lineLoginUrl == null)
        throw Exception('LINE Login URL is not available.');
      final Uri url = Uri.parse(_lineLoginUrl!);

      if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
        throw Exception('Could not launch the URL.');
      }

      // 店舗追加モードでない場合ログアウトを実行
      if (widget.mode != 'add_store') {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'LINEを開けません。アプリが設置されているか確認をお願いします。';
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
    if (_role == 'manager') {
      return [
        _buildRoleStep(),
        _buildManagerInfoStep1(),
        _buildManagerInfoStep2(),
        _buildLineIntegrationStep()
      ];
    } else if (_role == 'staff') {
      return [_buildRoleStep(), _buildStaffInfoStep1(), _buildStaffInfoStep2()];
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
            // PageViewのchildrenが変更された後、次のframeでページ移動
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

  Widget _buildManagerInfoStep1() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('管理者情報',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('ログイン及び本人確認のために情報を入力してください。',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          _buildTextField(
              controller: managerEmailController,
              label: 'メールアドレス',
              type: TextInputType.emailAddress),
          _buildTextField(
              controller: managerPasswordController,
              label: 'パスワード',
              isPassword: true),
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
          const SizedBox(height: 24),
          const Text('営業許可証',
              style: TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: _licenseImageFile == null
                  ? const Center(
                      child: Icon(Icons.add_a_photo_outlined,
                          color: AppColors.textSecondary, size: 40))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(_licenseImageFile!, fit: BoxFit.cover)),
            ),
          ),
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

  Widget _buildLineIntegrationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
        const SizedBox(height: 24),
        const Text('申請が仮受付されました。',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        const Text(
            '最後に、ご本人確認のためにLINEアカウントを連携してください。下のボタンを押して、LINEで申請を完了してください。',
            style: TextStyle(
                fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center),
        const Spacer(),
        _buildActionButton(
          label: 'LINEで申請完了',
          onPressed: () {
            // print("--- LINEで申請完了 버튼 클릭됨 ---");
            // print("현재 _isLoading 상태: $_isLoading");
            // print("현재 _lineLoginUrl: $_lineLoginUrl");

            // _isLoadingで無い時のみ、関数を呼び出すように防御コードを追加
            if (!_isLoading) {
              _launchLineLogin();
            }
          },
          isLoading: _isLoading,
          isLineButton: true,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

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

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      bool isPassword = false,
      TextInputType? type}) {
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
