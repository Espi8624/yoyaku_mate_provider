import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/models/provider_profile.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart'; // ApiException を使用する為 import
import 'package:yoyaku_mate_provider/services/profile_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  int _step = 0;
  String? _role;
  bool _isLoading = false;
  String? _errorMessage;
  String? _lineLoginUrl;

  // 戻るボタンのホバーステータス
  bool _isBackButtonHovered = false;

  // 画像ファイルを保持するステータス変数
  File? _licenseImageFile;
  final ImagePicker _picker = ImagePicker();

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
  void dispose() {
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
      print("Attempting to pick image...");
      File? selectedFile;

      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        // desktop -> file_picker 使用
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          selectedFile = File(result.files.single.path!);
          print("Image picked via file_picker: ${result.files.single.path}");
        } else {
          print("No image selected via file_picker.");
        }
      } else {
        // mobile -> image_picker 使用
        final XFile? pickedFile =
            await _picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          selectedFile = File(pickedFile.path);
          print("Image picked via image_picker: ${pickedFile.path}");
        } else {
          print("No image selected via image_picker.");
        }
      }

      if (selectedFile != null) {
        setState(() {
          _licenseImageFile = selectedFile;
          _errorMessage = null; // エラーメッセージをクリア
        });
      } else {
        setState(() {
          _errorMessage = "イメージが選択されていません";
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      setState(() {
        _errorMessage = "イメージ選択中にエラー発生: $e";
      });
    }
  }

  Future<void> _handleSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    User? newUser;
    try {
      final email = _role == 'manager'
          ? managerEmailController.text.trim()
          : staffEmailController.text.trim();
      final password = _role == 'manager'
          ? managerPasswordController.text
          : staffPasswordController.text;

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      newUser = userCredential.user;
      if (newUser == null) throw Exception('Firebase user creation failed.');

      final idToken = await newUser.getIdToken(true);
      if (idToken == null)
        throw Exception('Failed to retrieve Firebase ID token.');

      late final ProviderProfile profile;
      if (_role == 'manager') {
        profile = ProviderProfile(
          firebaseUid: newUser.uid,
          email: managerEmailController.text.trim(),
          phoneNumber: managerPhoneController.text,
          name: managerNameController.text,
          role: 'manager',
          storeName: storeNameController.text,
          storeAddress: storeAddressController.text,
          storeTelNumber: storePhoneController.text,
          bizNumber: null, // bizNumber는 이제 사용하지 않음
          storeEmail: managerEmailController.text.trim(),
        );
      } else {
        // staff
        final profileService =
            ProviderProfileService(baseUrl: 'http://localhost:8080');
        final storeExists =
            await profileService.checkStoreExists(staffStoreIdController.text);
        if (!storeExists) throw Exception('指定された店番号は存在しません');

        profile = ProviderProfile(
          firebaseUid: newUser.uid,
          email: staffEmailController.text.trim(),
          phoneNumber: staffPhoneController.text,
          name: staffNameController.text,
          role: 'staff',
          storeId: staffStoreIdController.text,
        );
      }

      final profileService =
          ProviderProfileService(baseUrl: 'http://localhost:8080');

      final createdProfileMap = await profileService.signUp(profile, idToken);

      String? storeId;
      String? lineLoginUrl;

      // バックエンド応答から 'data' オブジェクトを検索し、その中から 'store_id' を抽出
      if (createdProfileMap.containsKey('data') &&
          createdProfileMap['data'] is Map) {
        final userData = createdProfileMap['data'] as Map<String, dynamic>;
        storeId = userData['store_id'] as String?;
        lineLoginUrl = userData['line_login_url'] as String?;
      }

      // 管理者で、ライセンス画像が選択され、storeIdが存在する場合のみアップロードを実行
      if (_role == 'manager' && _licenseImageFile != null && storeId != null) {
        await profileService.uploadLicenseImage(storeId, _licenseImageFile!);
      }

      // 会員加入完了処理
      if (_role == 'manager' &&
          lineLoginUrl != null &&
          lineLoginUrl.isNotEmpty) {
        // managerの場合、URLをstateに保存し、_step=3に変更し、LINE連動UIを表示
        final uri = Uri.parse(lineLoginUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          await FirebaseAuth.instance.signOut();
          if (mounted) {
            context.go('/signup/complete');
          }
        } else {
          throw Exception('Could not launch LINE login URL');
        }
      } else {
        // staffか、managerにも関わらずURLをもらえなかった場合
        // ログアウトされ、ログインページに遷移
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('会員登録が完了しました。ログインしてください')),
          );
          context.go('/login');
        }
      }
    } catch (e) {
      if (newUser != null) {
        await newUser.delete();
      }
      if (mounted) {
        // ApiException と一般 Exception を区別し、メッセージを表示
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('新規登録'),
        // backgroundColor: AppColors.background,
        // foregroundColor: AppColors.textPrimary,
        elevation: 0,
        // Stackの代わりにAppBarのleadingを使用し、戻るを具現
        leading: _step > 0
            ? MouseRegion(
                onEnter: (event) => setState(() => _isBackButtonHovered = true),
                onExit: (event) => setState(() => _isBackButtonHovered = false),
                cursor: SystemMouseCursors.click,
                child: AnimatedScale(
                  scale: _isBackButtonHovered ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textSecondary),
                    style: IconButton.styleFrom(
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    onPressed: () {
                      setState(() {
                        // LINE連動段階(_step=3)では以前情報入力段階(_step=2)に戻る
                        if (_step == 3) {
                          _step = 2;
                        } else {
                          _step--;
                        }
                        _errorMessage = null;
                      });
                    },
                  ),
                ),
              )
            : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    // 現在ステップに応じたウィジェットを保持する変数
    Widget contentWidget;

    if (_step == 0) {
      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('どちらで会員加入を進みますか？',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRoleButton(
                icon: Icons.storefront,
                label: '管理者',
                onPressed: () => setState(() {
                  _role = 'manager';
                  _step = 1;
                }),
                isPrimary: true,
              ),
              const SizedBox(width: 24),
              _buildRoleButton(
                icon: Icons.person_outline,
                label: '職員',
                onPressed: () => setState(() {
                  _role = 'staff';
                  _step = 1;
                }),
              ),
            ],
          ),
        ],
      );
    } else if (_role == 'manager') {
      if (_step == 1) {
        contentWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 36),
            const Text('ユーザー情報入力',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
                controller: managerEmailController,
                decoration: const InputDecoration(labelText: 'メールアドレス'),
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            TextField(
                controller: managerPasswordController,
                decoration: const InputDecoration(labelText: 'パスワード'),
                obscureText: true),
            const SizedBox(height: 16),
            TextField(
                controller: managerPhoneController,
                decoration: const InputDecoration(labelText: '電話番号'),
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            TextField(
                controller: managerNameController,
                decoration: const InputDecoration(labelText: '名前')),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  foregroundColor: AppColors.textPrimaryLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: () => setState(() => _step = 2),
              child: const Text('次へ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      } else if (_step == 2) {
        contentWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 36),
            const Text('店情報入力',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
                controller: storeNameController,
                decoration: const InputDecoration(labelText: '店名')),
            const SizedBox(height: 16),
            TextField(
                controller: storeAddressController,
                decoration: const InputDecoration(labelText: '住所')),
            const SizedBox(height: 16),
            TextField(
                controller: storePhoneController,
                decoration: const InputDecoration(labelText: '電話番号'),
                keyboardType: TextInputType.phone),
            const SizedBox(height: 24),
            const Text('営業許可証',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: _licenseImageFile == null
                    ? const Text('アップロードするイメージ',
                        style: TextStyle(color: AppColors.textSecondary))
                    : Image.file(_licenseImageFile!, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('ファイル選択'),
              onPressed: _pickImage,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  foregroundColor: AppColors.textPrimaryLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: _isLoading ? null : _handleSignUp,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.background, strokeWidth: 2))
                  : const Text('登録',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      } else if (_step == 3) {
        contentWidget = _buildLineIntegrationStep();
      } else {
        contentWidget = const SizedBox.shrink();
      }
    } else if (_role == 'staff') {
      if (_step == 1) {
        contentWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 36),
            const Text('店番号入力',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
                controller: staffStoreIdController,
                decoration: const InputDecoration(labelText: '店番号')),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  foregroundColor: AppColors.textPrimaryLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: () => setState(() => _step = 2),
              child: const Text('次へ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      } else if (_step == 2) {
        contentWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 36),
            const Text('情報入力',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
                controller: staffEmailController,
                decoration: const InputDecoration(labelText: 'メールアドレス'),
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            TextField(
                controller: staffPasswordController,
                decoration: const InputDecoration(labelText: 'パスワード'),
                obscureText: true),
            const SizedBox(height: 16),
            TextField(
                controller: staffPhoneController,
                decoration: const InputDecoration(labelText: '電話番号'),
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            TextField(
                controller: staffNameController,
                decoration: const InputDecoration(labelText: '名前')),
            const SizedBox(height: 32),
            if (_errorMessage != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  foregroundColor: AppColors.textPrimaryLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: _isLoading ? null : _handleSignUp,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.background, strokeWidth: 2))
                  : const Text('登録',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      } else {
        contentWidget = const SizedBox.shrink();
      }
    } else {
      contentWidget = const SizedBox.shrink();
    }

    return contentWidget;
  }

  Widget _buildRoleButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    const double buttonSize = 130.0;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(buttonSize, buttonSize),
        backgroundColor:
            isPrimary ? AppColors.accentPrimary : AppColors.background,
        foregroundColor:
            isPrimary ? AppColors.textPrimaryLight : AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // LINE連動を案内するUIを生成
  Widget _buildLineIntegrationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 36),
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
        const SizedBox(height: 24),
        const Text(
          '申請が仮受付されました。',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          '最後に、ご本人確認と今後のお知らせのためにLINEアカウントを連携してください。下のボタンを押して、LINEで申請を完了してください。',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B900), // LINE Green Color
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _isLoading ? null : _launchLineLogin,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text(
                  'LINEで申請完了',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  // LINEログインを実行
  Future<void> _launchLineLogin() async {
    if (_lineLoginUrl == null) return;

    final Uri url = Uri.parse(_lineLoginUrl!);
    if (await canLaunchUrl(url)) {
      // 外部URLを開く
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = 'LINEを開けません。アプリが設置されているか確認をお願いします。';
        });
      }
    }
  }
}
