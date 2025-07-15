import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/profile_service.dart';
import '../models/provider_profile.dart';
import 'login_page.dart'; // Added import for LoginPage

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  int _step = 0; // 0: 권한선택, 1: 사장-유저정보, 2: 사장-가게정보, 1: 직원-가게번호, 2: 직원-유저정보
  String? _role; // 'owner' or 'staff'
  bool _isLoading = false;
  String? _errorMessage;

  // 사장 정보
  final TextEditingController ownerEmailController = TextEditingController();
  final TextEditingController ownerPasswordController = TextEditingController(); // 추가
  final TextEditingController ownerPhoneController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController storeAddressController = TextEditingController();
  final TextEditingController storePhoneController = TextEditingController();
  final TextEditingController storeBizNumController = TextEditingController();

  // 직원 정보
  final TextEditingController staffStoreIdController = TextEditingController();
  final TextEditingController staffEmailController = TextEditingController();
  final TextEditingController staffPasswordController = TextEditingController(); // 추가
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
          const Text('회원 유형을 선택하세요', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F61),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() { _role = 'owner'; _step = 1; });
            },
            child: const Text('사장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            child: const Text('직원', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    if (_role == 'owner' && _step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('사장 정보 입력', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: ownerEmailController,
            decoration: const InputDecoration(labelText: '이메일'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: ownerPasswordController,
            decoration: const InputDecoration(labelText: '비밀번호'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: ownerPhoneController,
            decoration: const InputDecoration(labelText: '휴대전화번호'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: ownerNameController,
            decoration: const InputDecoration(labelText: '유저이름'),
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
            child: const Text('다음', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    if (_role == 'owner' && _step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('가게 정보 입력', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: storeNameController,
            decoration: const InputDecoration(labelText: '가게이름'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: storeAddressController,
            decoration: const InputDecoration(labelText: '가게주소'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: storePhoneController,
            decoration: const InputDecoration(labelText: '가게 전화번호'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: storeBizNumController,
            decoration: const InputDecoration(labelText: '사업자번호'),
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
                : const Text('완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    if (_role == 'staff' && _step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('가게번호 입력', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: staffStoreIdController,
            decoration: const InputDecoration(labelText: '가게번호(store_id)'),
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
            child: const Text('다음', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    if (_role == 'staff' && _step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('직원 정보 입력', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: staffEmailController,
            decoration: const InputDecoration(labelText: '이메일'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: staffPasswordController,
            decoration: const InputDecoration(labelText: '비밀번호'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: staffPhoneController,
            decoration: const InputDecoration(labelText: '휴대전화번호'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: staffNameController,
            decoration: const InputDecoration(labelText: '유저이름'),
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
                : const Text('완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _handleOwnerSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create user with Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: ownerEmailController.text,
        password: ownerPasswordController.text, // 입력받은 비밀번호 사용
      );

      // Create provider profile
      final profile = ProviderProfile(
        firebaseUid: userCredential.user!.uid,
        email: ownerEmailController.text,
        phoneNumber: ownerPhoneController.text,
        name: ownerNameController.text,
        role: 'owner',
        storeName: storeNameController.text,
        storeAddress: storeAddressController.text,
        storeTelNumber: storePhoneController.text,
        bizNumber: storeBizNumController.text.isEmpty ? null : storeBizNumController.text,
        storeEmail: ownerEmailController.text,  // 가게 이메일을 사장님 이메일과 동일하게 설정
      );

      final profileService = ProviderProfileService(baseUrl: 'http://localhost:8080'); // Adjust the base URL as needed
      await profileService.signUp(profile);

      // Navigate to login page
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

  Future<void> _handleStaffSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileService = ProviderProfileService(baseUrl: 'http://localhost:8080');
      
      // Check if store exists
      final storeExists = await profileService.checkStoreExists(staffStoreIdController.text);
      if (!storeExists) {
        throw Exception('Store not found');
      }

      // Create user with Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: staffEmailController.text,
        password: staffPasswordController.text, // 입력받은 비밀번호 사용
      );

      // Create provider profile
      final profile = ProviderProfile(
        firebaseUid: userCredential.user!.uid,
        email: staffEmailController.text,
        phoneNumber: staffPhoneController.text,
        name: staffNameController.text,
        role: 'staff',
      );

      await profileService.signUp(profile);

      // Navigate to login page
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
