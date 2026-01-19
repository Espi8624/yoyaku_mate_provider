import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/models/provider_profile.dart'; // 必要なモデルが存在し、エクスポートされていることを確認
import 'package:yoyaku_mate_provider/models/store_profile.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen_viewmodel.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/steps/store_wizard_steps.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

class AddStorePage extends StatefulWidget {
  const AddStorePage({super.key});

  @override
  State<AddStorePage> createState() => _AddStorePageState();
}

class _AddStorePageState extends State<AddStorePage> {
  bool _isLoading = false;

  // Controllers
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameKanaController = TextEditingController();
  final _firstNameKanaController = TextEditingController();

  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storePhoneController = TextEditingController();
  final _estimatedWaitTimeController = TextEditingController(text: '10');
  final _maxWaitingCountController = TextEditingController(text: '10');
  bool _enableMenuSelection = false;

  final PageController _pageController = PageController();
  int _currentPage = 0;

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
    _estimatedWaitTimeController.dispose();
    _maxWaitingCountController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
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
      // プロフィールの既存の電話番号を使用
      final phoneNumber = userProfile?.phone_number ?? '';

      // 名前を結合 (姓名)
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
        estimatedWaitTime:
            int.tryParse(_estimatedWaitTimeController.text) ?? 10,
        maxWaitingCount: int.tryParse(_maxWaitingCountController.text) ?? 10,
        enableMenuSelection: _enableMenuSelection,
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
      if (!mounted) return;
      ToastWidget.show(context, '新しい店舗が追加されました。', type: ToastType.success);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ToastWidget.show(
        context,
        "エラー : ${e is ApiException ? e.message : e.toString()}",
        type: ToastType.error,
      );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary),
          onPressed: () {
            if (_pageController.hasClients && _pageController.page! > 0) {
              _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            } else {
              context.pop();
            }
          },
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator (optional)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 5,
                backgroundColor: AppColors.border,
                color: AppColors.accentPrimary,
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 24.0),
                    child: StoreBasicInfoStep(
                      nameController: _storeNameController,
                      addressController: _storeAddressController,
                      phoneController: _storePhoneController,
                      onNext: _nextPage,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 24.0),
                    child: StoreCapacityStep(
                      maxWaitingCountController: _maxWaitingCountController,
                      onNext: _nextPage,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 24.0),
                    child: StoreTimeStep(
                      estimatedWaitTimeController: _estimatedWaitTimeController,
                      onNext: _nextPage,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 24.0),
                    child: StorePreOrderStep(
                      isPreOrderEnabled: _enableMenuSelection,
                      onPreOrderChanged: (val) {
                        setState(() {
                          _enableMenuSelection = val;
                        });
                      },
                      onNext: _nextPage,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 24.0),
                    child: StoreReviewStep(
                      nameController: _storeNameController,
                      addressController: _storeAddressController,
                      phoneController: _storePhoneController,
                      maxWaitingCountController: _maxWaitingCountController,
                      estimatedWaitTimeController: _estimatedWaitTimeController,
                      isPreOrderEnabled: _enableMenuSelection,
                      onSubmit: _submit,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
