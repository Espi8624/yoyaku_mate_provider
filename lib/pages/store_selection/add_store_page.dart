import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/models/provider_profile.dart'; // Ensure these models exist and are exported
import 'package:yoyaku_mate_provider/models/store_profile.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen_viewmodel.dart';
import 'package:yoyaku_mate_provider/pages/store_selection/widgets/store_info_form.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';

class AddStorePage extends StatefulWidget {
  const AddStorePage({super.key});

  @override
  State<AddStorePage> createState() => _AddStorePageState();
}

class _AddStorePageState extends State<AddStorePage> {
  bool _isLoading = false;
  String? _errorMessage;

  // Controllers
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameKanaController = TextEditingController();
  final _firstNameKanaController = TextEditingController();

  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storePhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateUserData();
    });
  }

  void _populateUserData() {
    final profileVM = context.read<ProfileScreenViewModel>();
    final userProfile = profileVM.userProfile;

    if (userProfile != null) {
      final rawName =
          userProfile.name.replaceAll(RegExp(r'[\u3000\s]+'), ' ').trim();
      if (rawName.isNotEmpty) {
        final parts = rawName.split(RegExp(r'\s+'));
        if (parts.length == 1) {
          _lastNameController.text = parts[0];
        } else {
          _lastNameController.text = parts.first;
          _firstNameController.text = parts.sublist(1).join(' ');
        }
      }
    }
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _lastNameKanaController.dispose();
    _firstNameKanaController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw ApiException('ログイン状態が確認できません。');
      }

      final firebaseUid = currentUser.uid;
      final profileVM = context.read<ProfileScreenViewModel>();
      final userProfile = profileVM.userProfile;

      final idToken = await currentUser.getIdToken(true);
      if (idToken == null) {
        throw Exception('Failed to retrieve Firebase ID token.');
      }

      final profileService =
          ProviderProfileService(baseUrl: 'https://saboten-server.fly.dev');

      final email = userProfile?.email ?? currentUser.email ?? '';
      // Use existing phone number from profile
      final phoneNumber = userProfile?.phone_number ?? '';

      // Combine Names
      final lastName = _lastNameController.text.trim();
      final firstName = _firstNameController.text.trim();
      final fullName = '$lastName $firstName'.trim();

      final lastNameKana = _lastNameKanaController.text.trim();
      final firstNameKana = _firstNameKanaController.text.trim();
      final fullNameFurigana = '$lastNameKana $firstNameKana'.trim();

      final profile = ProviderProfile(
        firebaseUid: firebaseUid,
        email: email,
        phoneNumber: phoneNumber,
        name: fullName,
        nameFurigana: fullNameFurigana,
        role: 'manager',
        storeName: _storeNameController.text.trim(),
        storeAddress: _storeAddressController.text.trim(),
        storeTelNumber: _storePhoneController.text.trim(),
        storeEmail: email,
        termsAgreed: true,
        privacyAgreed: true,
      );

      final createdProfileMap =
          await profileService.addNewStore(profile, idToken);

      if (!mounted) return;

      // addNewStoreが返すstoreをそのままStoreProfileに変換してローカルリスト(myStores)に追加する
      final storeJson = createdProfileMap['store'] as Map<String, dynamic>?;
      if (storeJson != null) {
        final newStoreProfile = StoreProfile.fromJson(storeJson);
        profileVM.addStore(newStoreProfile);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新しい店舗が追加されました。')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "エラー : ${e is ApiException ? e.message : e.toString()}";
      });
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: StoreInfoForm(
            nameController: _storeNameController,
            addressController: _storeAddressController,
            phoneController: _storePhoneController,
            onSubmit: _submit,
            isLoading: _isLoading,
            errorMessage: _errorMessage,
          ),
        ),
      ),
    );
  }
}
