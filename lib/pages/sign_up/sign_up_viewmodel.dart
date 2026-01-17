import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoyaku_mate_provider/models/provider_profile.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';
import 'package:yoyaku_mate_provider/utils/phone_formatter.dart';
import 'package:yoyaku_mate_provider/routes.dart' show setSignUpInProgress;

class SignUpViewModel extends ChangeNotifier {
  final ProviderProfileService _profileService;

  SignUpViewModel({ProviderProfileService? profileService})
      : _profileService = profileService ??
            ProviderProfileService(baseUrl: 'https://saboten-server.fly.dev');

  // State Variables
  String? _role;
  String? get role => _role;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentPageIndex = 0;
  int get currentPageIndex => _currentPageIndex;

  bool _isTermsAgreed = false;
  bool get isTermsAgreed => _isTermsAgreed;

  bool _isPrivacyAgreed = false;
  bool get isPrivacyAgreed => _isPrivacyAgreed;

  bool _isEmailVerified = false;
  bool get isEmailVerified => _isEmailVerified;

  bool _isPhoneVerified = false;
  bool get isPhoneVerified => _isPhoneVerified;

  // Phone Auth State
  String? _verificationId;
  int? _resendToken;

  // Internal
  User? _pendingUser;
  bool _isInitialized = false;

  // Setters
  void setRole(String role) {
    _role = role;
    notifyListeners();
  }

  void setTermsAgreed(bool value) {
    _isTermsAgreed = value;
    notifyListeners();
  }

  void setPrivacyAgreed(bool value) {
    _isPrivacyAgreed = value;
    notifyListeners();
  }

  void reset() {
    _role = null;
    _isTermsAgreed = false;
    _isPrivacyAgreed = false;
    _currentPageIndex = 0;
    _errorMessage = null;
    _isLoading = false;
    _isEmailVerified = false;
    _isPhoneVerified = false;
    _verificationId = null;
    _resendToken = null;
    _pendingUser = null;
    notifyListeners();
  }

  void setCurrentPageIndex(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  void setErrorMessage(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // --- Logic Methods ---

  // Load Progress from SharedPreferences
  Future<int> loadSignUpProgress(String? widgetMode) async {
    if (_isInitialized) return _currentPageIndex;
    _isInitialized = true;

    if (widgetMode == 'add_store') {
      // logic handled in view setup roughly, but here we can just return
      // The view handles initialPage logic for add_store
      return widgetMode == 'add_store' ? (_role == 'staff' ? 6 : 7) : 0;
    }

    final prefs = await SharedPreferences.getInstance();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // Fresh Start
      await prefs.remove('signup_role');
      await prefs.remove('terms_agreed');
      return 0; // Role Selection
    }

    // Resume Flow
    final savedRole = prefs.getString('signup_role');
    final savedTerms = prefs.getBool('terms_agreed') ?? false;

    if (savedRole != null) _role = savedRole;
    _isTermsAgreed = savedTerms;
    _isPrivacyAgreed = savedTerms;

    _pendingUser = currentUser;
    await currentUser.reload();

    _isEmailVerified = currentUser.emailVerified;
    if (currentUser.phoneNumber != null &&
        currentUser.phoneNumber!.isNotEmpty) {
      _isPhoneVerified = true;
    }

    final savedPhone = prefs.getString('signup_phone');
    if (savedPhone != null && !_isPhoneVerified) {
      // Logic if we want to use saved phone as a fallback for verification UI
    }

    notifyListeners();

    // Determine Target Page
    if (_role == null) return 0;
    if (!savedTerms) return 1;
    if (!_isEmailVerified) return 5;
    if (!_isPhoneVerified) return 6; // Phone Verification

    return 8; // User/Store Info
  }

  Future<void> saveSignUpProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (_role != null) {
      await prefs.setString('signup_role', _role!);
    }
    await prefs.setBool('terms_agreed', _isTermsAgreed);
    // Note: phone number is usually managed by controllers in View,
    // but we can save the internal version if we want to survive app kills.
  }

  Future<void> savePhoneProgress(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('signup_phone', phone);
  }

  // Check Email Duplicate
  Future<bool> checkEmailDuplicate(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      bool isOwnEmail = (currentUser != null && currentUser.email == email);

      if (!isOwnEmail) {
        final isAvailable = await _profileService.checkEmailAvailability(email);
        if (!isAvailable) {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'このメールアドレスは既に使用されています。',
          );
        }
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // View should handle showing login dialog based on this specific error or return false/enum
        rethrow;
      }
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'エラーが発生しました: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Account
  Future<bool> createAccountAndSendEmail(
      String email, String password, String mode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      setSignUpInProgress(true);
      final currentUser = FirebaseAuth.instance.currentUser;
      final isResume = mode == 'resume' ||
          (currentUser != null && currentUser.email == email);

      if (isResume) {
        User? user = _pendingUser ?? currentUser;
        if (user != null) {
          _pendingUser = user;
          if (!user.emailVerified) {
            await user.sendEmailVerification();
          }
        } else {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'このメールアドレスは既に使用されています。',
          );
        }
      } else {
        // Validation handled in View (Form Key)
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        _pendingUser = userCredential.user;
        if (_pendingUser == null) throw Exception('アカウント作成に失敗しました。');

        await _pendingUser!.sendEmailVerification();
        // Removed signOut() to keep the session active during verification flow
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        rethrow; // Let View handle dialog
      } else if (e.code == 'weak-password') {
        _errorMessage = 'パスワードが弱すぎます。';
      } else {
        _errorMessage = 'アカウント作成に失敗しました: ${e.message}';
      }
      return false;
    } catch (e) {
      _errorMessage = 'エラーが発生しました: $e';
      return false;
    } finally {
      setSignUpInProgress(false);
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify Email Complete
  Future<bool> verifyEmailComplete(
      String emailInput, String passwordInput) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      setSignUpInProgress(true);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await currentUser.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null && refreshedUser.emailVerified) {
          _isEmailVerified = true;
          return true;
        }
      } else {
        // Retry Logic
        if (emailInput.isNotEmpty && passwordInput.isNotEmpty) {
          try {
            final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: emailInput.trim(),
              password: passwordInput,
            );
            if (cred.user != null) {
              await cred.user!.reload();
              if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
                _isEmailVerified = true;
                return true;
              } else {
                // Sign in succeeded but still not verified
                return false;
              }
            }
          } catch (_) {
            // absorb
          }
        }
        throw Exception('セッションが切れました。再度ログインしてください。');
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      setSignUpInProgress(false);
      _isLoading = false;
      notifyListeners();
    }
  }

  // Resend Email
  Future<bool> resendEmailLink(
      String emailInput, String passwordInput, String mode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      setSignUpInProgress(true);
      User? user;
      if (mode == 'resume' && FirebaseAuth.instance.currentUser != null) {
        user = FirebaseAuth.instance.currentUser;
      } else {
        // Silently re-login
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailInput.trim(),
          password: passwordInput,
        );
        user = cred.user;
      }

      await user?.sendEmailVerification();
      // NOTE: Removed signOut() as per recent fix
      return true;
    } catch (e) {
      _errorMessage = 'メール送信失敗: $e';
      return false;
    } finally {
      setSignUpInProgress(false);
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Phone Auth Logic ---

  Future<bool> sendPhoneCode(String phoneNumber, String role) async {
    // Note: Validation is done in View
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      setSignUpInProgress(true);
      final rawPhoneNumber = phoneNumber.trim();
      final internalNumberString =
          PhoneFormatter.formatPhoneNumberForInternal(rawPhoneNumber);
      final phoneNumberForFirebase = _formatPhoneNumber(internalNumberString);

      final completer = Completer<bool>();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumberForFirebase,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-complete logic can go here, but usually codeSent is main flow
          // For simplicity in MVVM, we might just expose a stream or callback
          // But let's assume we proceed manually or handle it via a listener if needed
          _isPhoneVerified = true;
          notifyListeners();
        },
        verificationFailed: (FirebaseAuthException e) {
          String msg = '認証に失敗しました: ${e.message}';
          if (e.code == 'invalid-phone-number') msg = '電話番号の形式が正しくありません。';
          if (e.code == 'too-many-requests')
            msg = '試行回数が多すぎます。しばらくしてから再度お試しください。';
          _errorMessage = msg;
          _isLoading = false;
          setSignUpInProgress(false);
          notifyListeners();
          if (!completer.isCompleted) completer.complete(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isLoading = false;
          // setSignUpInProgress remains true
          notifyListeners();
          if (!completer.isCompleted) completer.complete(true);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          // notifyListeners();
        },
        forceResendingToken: _resendToken,
      );

      return completer.future;
    } catch (e) {
      setSignUpInProgress(false);
      _errorMessage = 'エラーが発生しました: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[-\s]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    return '+81$cleaned';
  }

  Future<bool> verifyPhoneCode(String code) async {
    if (code.isEmpty || code.length != 6) {
      _errorMessage = '6桁の認証コードを入力してください。';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    setSignUpInProgress(true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.linkWithCredential(credential);
      } else {
        await FirebaseAuth.instance.signInWithCredential(credential);
        await FirebaseAuth.instance.signOut();
      }

      _isPhoneVerified = true;
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        _errorMessage = '認証コードが正しくありません。';
      } else if (e.code == 'session-expired') {
        _errorMessage = '認証コードの有効期限が切れました。再度送信してください。';
      } else {
        _errorMessage = '認証に失敗しました: ${e.message}';
      }
      return false;
    } catch (e) {
      _errorMessage = 'エラーが発生しました: $e';
      return false;
    } finally {
      setSignUpInProgress(false);
      if (_isPhoneVerified) {
        // Keep loading true for transition usually, but simplest to reset
        _isLoading = false;
      } else {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<bool> handleSignUp({
    required String? mode,
    required String? managerName,
    required String? managerNameKana,
    required String? storeName,
    required String? storeAddress,
    required String? storePhone,
    required String? staffName,
    required String? staffNameKana,
    required String? staffStoreId,
    required String managerPhoneInput, // 内部フォーマットチェック用
    required String staffPhoneInput,
    int estimatedWaitTime = 10,
    int maxWaitingCount = 10,
    bool isPreOrderEnabled = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    setSignUpInProgress(true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw ApiException('ユーザー情報が見つかりません。再ログインしてください。');
      }

      final idToken = await currentUser.getIdToken();
      if (idToken == null) throw ApiException('認証トークンの取得に失敗しました。');

      // Call API based on role/mode
      bool isAddingStore = mode == 'add_store';

      if (_role == 'manager') {
        if (isAddingStore) {
          final internalManagerPhone =
              PhoneFormatter.formatPhoneNumberForInternal(managerPhoneInput);

          // "Add Store"の場合、店舗情報を運ぶためにProviderProfileを使用
          // バックエンドはおそらくこのフラットな構造から店舗情報を抽出する
          final profile = ProviderProfile(
            firebaseUid: currentUser.uid,
            email: currentUser.email!,
            phoneNumber: internalManagerPhone,
            name: managerName!,
            nameFurigana: managerNameKana!,
            role: 'manager',
            storeName: storeName,
            storeAddress: storeAddress,
            storeTelNumber:
                PhoneFormatter.formatPhoneNumberForInternal(storePhone!),
            // 事業者番号はまだフォームにない？
            estimatedWaitTime: estimatedWaitTime,
            maxWaitingCount: maxWaitingCount,
            enableMenuSelection: isPreOrderEnabled,
          );

          await _profileService.addNewStore(profile, idToken);
        } else {
          final internalManagerPhone =
              PhoneFormatter.formatPhoneNumberForInternal(managerPhoneInput);
          final profile = ProviderProfile(
            firebaseUid: currentUser.uid,
            email: currentUser.email!,
            phoneNumber: internalManagerPhone,
            name: managerName!,
            nameFurigana: managerNameKana!,
            role: 'manager',
            storeName: storeName,
            storeAddress: storeAddress,
            storeTelNumber:
                PhoneFormatter.formatPhoneNumberForInternal(storePhone!),
            estimatedWaitTime: estimatedWaitTime,
            maxWaitingCount: maxWaitingCount,
            enableMenuSelection: isPreOrderEnabled,
          );

          await _profileService.signUp(profile, idToken);
        }
      } else {
        // Staff
        if (isAddingStore) {
          await _profileService.joinStore(staffStoreId!);
        } else {
          final internalStaffPhone =
              PhoneFormatter.formatPhoneNumberForInternal(staffPhoneInput);
          final profile = ProviderProfile(
            firebaseUid: currentUser.uid,
            email: currentUser.email!,
            phoneNumber: internalStaffPhone,
            name: staffName!,
            nameFurigana: staffNameKana!,
            role: 'staff',
            storeId: staffStoreId,
          );
          await _profileService.signUp(profile, idToken);
        }
      }

      // Final Cleanup
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('signup_role');
      await prefs.remove('terms_agreed');
      await prefs.remove('signup_phone');

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'エラーが発生しました: $e';
      return false;
    } finally {
      setSignUpInProgress(false);
      _isLoading = false;
      notifyListeners();
    }
  }
}
