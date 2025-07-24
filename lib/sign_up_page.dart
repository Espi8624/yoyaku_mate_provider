import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/profile_service.dart';
import '../models/provider_profile.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  int _step = 0; // 0: 権限選択, 1: 管理者-個人情報, 2: 管理者-店情報, 1: 職員-店番号, 2: 職員-個人情報
  String? _role; // 'manager' or 'staff'
  bool _isLoading = false;
  String? _errorMessage;

  // 管理者情報
  final TextEditingController managerEmailController = TextEditingController();
  final TextEditingController managerPasswordController = TextEditingController();
  final TextEditingController managerPhoneController = TextEditingController();
  final TextEditingController managerNameController = TextEditingController();
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController storeAddressController = TextEditingController();
  final TextEditingController storePhoneController = TextEditingController();
  final TextEditingController storeBizNumController = TextEditingController();

  // 職員情報
  final TextEditingController staffStoreIdController = TextEditingController();
  final TextEditingController staffEmailController = TextEditingController();
  final TextEditingController staffPasswordController = TextEditingController();
  final TextEditingController staffPhoneController = TextEditingController();
  final TextEditingController staffNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新規登録'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF263238),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
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
    if (_step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('どちらで会員加入を進みますか？', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F61),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() { _role = 'manager'; _step = 1; });
            },
            child: const Text('マネージャー', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0F1F3),
              foregroundColor: const Color(0xFF263238),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() { _role = 'staff'; _step = 1; });
            },
            child: const Text('職員', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    if (_role == 'manager' && _step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ユーザー情報入力', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: managerEmailController,
            decoration: const InputDecoration(labelText: 'メールアドレス'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: managerPasswordController,
            decoration: const InputDecoration(labelText: 'パスワード'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: managerPhoneController,
            decoration: const InputDecoration(labelText: '電話番号'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: managerNameController,
            decoration: const InputDecoration(labelText: '名前'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F61),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() { _step = 2; });
            },
            child: const Text('次へ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    if (_role == 'manager' && _step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('店情報入力', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: storeNameController,
            decoration: const InputDecoration(labelText: '店名'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: storeAddressController,
            decoration: const InputDecoration(labelText: '住所'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: storePhoneController,
            decoration: const InputDecoration(labelText: '電話番号'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: storeBizNumController,
            decoration: const InputDecoration(labelText: '事業者番号'),
          ),
          const SizedBox(height: 32),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F61),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isLoading ? null : _handleOwnerSignUp,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('登録', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    if (_role == 'staff' && _step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('店番号入力', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: staffStoreIdController,
            decoration: const InputDecoration(labelText: '店番号'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F61),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() { _step = 2; });
            },
            child: const Text('次へ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    if (_role == 'staff' && _step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('情報入力', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: staffEmailController,
            decoration: const InputDecoration(labelText: 'メールアドレス'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: staffPasswordController,
            decoration: const InputDecoration(labelText: 'パスワード'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: staffPhoneController,
            decoration: const InputDecoration(labelText: '電話番号'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: staffNameController,
            decoration: const InputDecoration(labelText: '名前'),
          ),
          const SizedBox(height: 32),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F61),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isLoading ? null : _handleStaffSignUp,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('登録', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  // 管理者側処理
  Future<void> _handleOwnerSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Firsebase Auth 使用しユーザー作成
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: managerEmailController.text,
        password: managerPasswordController.text,
      );

      // Create provider profile
      final profile = ProviderProfile(
        firebaseUid: userCredential.user!.uid,
        email: managerEmailController.text,
        phoneNumber: managerPhoneController.text,
        name: managerNameController.text,
        role: 'manager',
        storeName: storeNameController.text,
        storeAddress: storeAddressController.text,
        storeTelNumber: storePhoneController.text,
        bizNumber: storeBizNumController.text.isEmpty ? null : storeBizNumController.text,
        storeEmail: managerEmailController.text,  // 가게 이메일을 사장님 이메일과 동일하게 설정
      );

      // 基盤 URL 指定し、プロファイルサービス初期化
      final profileService = ProviderProfileService(baseUrl: 'http://localhost:8080');
      await profileService.signUp(profile);

      // 会員加入後、明示的にログアウト処理
      await FirebaseAuth.instance.signOut();

      // ログインページへ遷移
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginPage(onLoginSuccess: () {})),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 職員側処理
  Future<void> _handleStaffSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileService = ProviderProfileService(baseUrl: 'http://localhost:8080');
      
      // 店情報照会
      final storeExists = await profileService.checkStoreExists(staffStoreIdController.text);
      if (!storeExists) {
        throw Exception('Store not found');
      }

      // Firebase Auth を使用しユーザー作成
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: staffEmailController.text,
        password: staffPasswordController.text,
      );

      // profile 作成
      final profile = ProviderProfile(
        firebaseUid: userCredential.user!.uid,
        email: staffEmailController.text,
        phoneNumber: staffPhoneController.text,
        name: staffNameController.text,
        role: 'staff',
      );

      await profileService.signUp(profile);

      // 会員加入後、明示的にログアウト処理
      await FirebaseAuth.instance.signOut();

      // ログインページへ遷移
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginPage(onLoginSuccess: () {})),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
