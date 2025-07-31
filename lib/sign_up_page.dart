import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/models/provider_profile.dart';
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

  final TextEditingController managerEmailController = TextEditingController();
  final TextEditingController managerPasswordController =
      TextEditingController();
  final TextEditingController managerPhoneController = TextEditingController();
  final TextEditingController managerNameController = TextEditingController();
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController storeAddressController = TextEditingController();
  final TextEditingController storePhoneController = TextEditingController();
  final TextEditingController storeBizNumController = TextEditingController();

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
    storeBizNumController.dispose();
    staffStoreIdController.dispose();
    staffEmailController.dispose();
    staffPasswordController.dispose();
    staffPhoneController.dispose();
    staffNameController.dispose();
    super.dispose();
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
          bizNumber: storeBizNumController.text.isEmpty
              ? null
              : storeBizNumController.text,
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
      await profileService.signUp(profile, idToken);

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('会員登録が完了しました。ログインしてください')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (newUser != null) {
        await newUser.delete();
      }
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
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
        title: const Text('新規登録'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
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
    if (_step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('どちらで会員加入を進みますか？',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainAccent,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => setState(() {
              _role = 'manager';
              _step = 1;
            }),
            child: const Text('マネージャー',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => setState(() {
              _role = 'staff';
              _step = 1;
            }),
            child: const Text('職員',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
        ],
      );
    }

    if (_role == 'manager') {
      if (_step == 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  backgroundColor: AppColors.mainAccent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: () => setState(() => _step = 2),
              child: const Text('次へ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
      if (_step == 2) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 16),
            TextField(
                controller: storeBizNumController,
                decoration: const InputDecoration(labelText: '事業者番号')),
            const SizedBox(height: 32),
            if (_errorMessage != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainAccent,
                  foregroundColor: AppColors.background,
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
      }
    }

    if (_role == 'staff') {
      if (_step == 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('店番号入力',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
                controller: staffStoreIdController,
                decoration: const InputDecoration(labelText: '店番号')),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainAccent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: () => setState(() => _step = 2),
              child: const Text('次へ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
      if (_step == 2) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  backgroundColor: AppColors.mainAccent,
                  foregroundColor: AppColors.background,
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
      }
    }

    return const SizedBox.shrink();
  }
}
