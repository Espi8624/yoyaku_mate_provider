import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoyaku_mate_provider/models/provider_profile.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';
import 'package:yoyaku_mate_provider/utils/phone_formatter.dart';
import 'package:yoyaku_mate_provider/routes.dart' show setSignUpInProgress;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SignUpViewModel extends ChangeNotifier {
  final ProviderProfileService _profileService;

  SignUpViewModel({ProviderProfileService? profileService})
      : _profileService = profileService ??
            ProviderProfileService(baseUrl: dotenv.env['API_URL']!);

  // 状態変数
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

  // 電話番号認証の状態
  String? _verificationId;
  int? _resendToken;

  // 内部変数
  User? _pendingUser;
  bool _isInitialized = false;

  // セッター
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

  // 営業時間の状態
  Map<String, Map<String, String>>? _operatingHours;
  Map<String, Map<String, String>>? get operatingHours => _operatingHours;

  bool _is24Hours = false;
  bool get is24Hours => _is24Hours;

  String _resetTime = '06:00';
  String get resetTime => _resetTime;

  void saveBusinessHours(
      Map<String, Map<String, String>> hours, bool is24h, String reset) {
    _operatingHours = hours;
    _is24Hours = is24h;
    _resetTime = reset;
    notifyListeners();
  }

  // --- Logic Methods ---

  // SharedPreferencesから進捗を読み込む
  Future<int> loadSignUpProgress(String? widgetMode) async {
    if (_isInitialized) return _currentPageIndex;
    _isInitialized = true;

    if (widgetMode == 'add_store') {
      // viewのセットアップでおおよそ処理されるが、ここでは単に戻す
      // add_store用の初期ページロジックはViewで処理される
      return widgetMode == 'add_store' ? (_role == 'staff' ? 6 : 7) : 0;
    }

    final prefs = await SharedPreferences.getInstance();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // 新規開始
      await prefs.remove('signup_role');
      await prefs.remove('terms_agreed');
      return 0; // 役割選択
    }

    // 再開フロー
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
      // 認証UIのフォールバックとして保存された電話番号を使用したい場合のロジック
    }

    notifyListeners();

    // ターゲットページを決定
    if (_role == null) return 0;
    if (!savedTerms) return 1;
    if (!_isEmailVerified) return 5;
    if (!_isPhoneVerified) return 6; // 電話番号認証

    return 8; // ユーザー/店舗情報
  }

  Future<void> saveSignUpProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (_role != null) {
      await prefs.setString('signup_role', _role!);
    }
    await prefs.setBool('terms_agreed', _isTermsAgreed);
    // メモ: 電話番号は通常Viewのコントローラーで管理されるが、
    // アプリキル後も維持したい場合は内部バージョンを保存可能
  }

  Future<void> savePhoneProgress(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('signup_phone', phone);
  }

  // メールアドレスの重複チェック
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
        // この特定のエラーに基づいてViewでログインダイアログを表示するか、false/enumを返す
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

  // アカウント作成
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
        // バリデーションはView(Form Key)で処理
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        _pendingUser = userCredential.user;
        if (_pendingUser == null) throw Exception('アカウント作成に失敗しました。');

        await _pendingUser!.sendEmailVerification();
        // 検証フローの間セッションを維持するためにsignOut()を削除
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        rethrow; // Viewでダイアログを処理させる
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

  // メール認証完了確認
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
        // 再試行ロジック
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
                // サインイン成功したが未認証
                return false;
              }
            }
          } catch (_) {
            // 無視
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

  // メール再送信
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
        // 静かに再ログイン
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailInput.trim(),
          password: passwordInput,
        );
        user = cred.user;
      }

      await user?.sendEmailVerification();
      // NOTE: 最近の修正に従いsignOut()を削除
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

  // --- 電話番号認証ロジック ---

  Future<bool> sendPhoneCode(String phoneNumber, String role) async {
    // メモ: バリデーションはViewで行われる
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
          // 自動完了ロジックをここに記述可能だが、通常はcodeSentがメインフロー
          // MVVMのシンプルさのため、ストリームやコールバックを公開するだけにしても良い
          // ここでは手動で進むか、必要ならリスナー経由で処理すると仮定
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
          // setSignUpInProgressはtrueのまま
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
    String? storeZipCode, // New
    String? storePrefecture, // New
    String? storeCity, // New
    String? storeBuilding, // New
    required String? storePhone,
    required String? staffName,
    required String? staffNameKana,
    required String? staffStoreId,
    required String managerPhoneInput, // 内部フォーマットチェック用
    required String staffPhoneInput,
    int estimatedWaitTime = 10,
    int maxWaitingCount = 10,
    bool isPreOrderEnabled = false,
    bool requireOneMenuPerPerson = false, // New parameter
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

          final profile = ProviderProfile(
            firebaseUid: currentUser.uid,
            email: currentUser.email!,
            phoneNumber: internalManagerPhone,
            name: managerName!,
            nameFurigana: managerNameKana!,
            role: 'manager',
            storeName: storeName,
            storeAddress: storeAddress,
            storeBuilding: storeBuilding,
            storeZipCode: storeZipCode,
            storePrefecture: storePrefecture,
            storeCity: storeCity,
            storeTelNumber:
                PhoneFormatter.formatPhoneNumberForInternal(storePhone!),
            estimatedWaitTime: estimatedWaitTime,
            maxWaitingCount: maxWaitingCount,
            enableMenuSelection: isPreOrderEnabled,
            requireOneMenuPerPerson: requireOneMenuPerPerson,
            operatingHours: _operatingHours,
            is24Hours: _is24Hours,
            resetTime: _resetTime,
          );

          await _profileService.addNewStore(profile, idToken);
        } else {
          // Refactor: Manager Sign Up (No Store)
          // 店舗情報が空でもユーザー作成リクエストを送る
          final internalManagerPhone =
              PhoneFormatter.formatPhoneNumberForInternal(managerPhoneInput);

          final profile = ProviderProfile(
            firebaseUid: currentUser.uid,
            email: currentUser.email!,
            phoneNumber: internalManagerPhone,
            name: managerName!,
            nameFurigana: managerNameKana!,
            role: 'manager',
            // 店舗情報は含めない (null または 空文字)
          );

          await _profileService.signUp(profile, idToken);
        }
      } else {
        // Staff
        if (isAddingStore) {
          await _profileService.joinStore(staffStoreId!);
        } else {
          // Refactor: Staff Sign Up (No Store)
          final internalStaffPhone =
              PhoneFormatter.formatPhoneNumberForInternal(staffPhoneInput);
          final profile = ProviderProfile(
            firebaseUid: currentUser.uid,
            email: currentUser.email!,
            phoneNumber: internalStaffPhone,
            name: staffName!,
            nameFurigana: staffNameKana!,
            role: 'staff',
            // 店舗IDは含めない
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
