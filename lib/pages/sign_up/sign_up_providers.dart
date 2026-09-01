// 会員登録ウィザードの状態管理 (Riverpod)
//
// Provider(MVVM)からの移行。/signup ルートにのみ紐づくページローカル状態
// (routes.dartでChangeNotifierProviderとしてルートスコープ注入されていたのと
// 同じ生存期間になるよう、@riverpod のデフォルトのautoDisposeをそのまま使う)。
//
// 既存ViewModelの notifyListeners() オーバーライド(_isDisposed チェック)は、
// Firebase Auth の電話番号認証コールバック(verifyPhoneNumber の
// verificationCompleted/verificationFailed/codeSent/codeAutoRetrievalTimeout)が
// ウィジェット破棄後にも非同期で発火し得ることへの防御だった。Riverpodでは
// dispose後にstateを書き込むと例外になるため、ref.onDispose()で立てる
// _isDisposedフラグを_updateState()内で確認するガードに置き換えて
// 同じ安全性を再現する (riverpod 2.6.1にはref.mountedが無いため)。
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoyaku_mate_provider/models/provider_profile.dart';
import 'package:yoyaku_mate_provider/routes.dart' show setSignUpInProgress;
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';
import 'package:yoyaku_mate_provider/utils/phone_formatter.dart';

part 'sign_up_providers.g.dart';

class SignUpState {
  final String? role;
  final bool isLoading;
  final String? errorMessage;
  final int currentPageIndex; // 現在のUIからは未使用だがAPI parityのため保持
  final bool isTermsAgreed;
  final bool isPrivacyAgreed;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final Map<String, Map<String, String>>? operatingHours;
  final bool is24Hours;
  final String resetTime;

  const SignUpState({
    this.role,
    this.isLoading = false,
    this.errorMessage,
    this.currentPageIndex = 0,
    this.isTermsAgreed = false,
    this.isPrivacyAgreed = false,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.operatingHours,
    this.is24Hours = false,
    this.resetTime = '06:00',
  });

  SignUpState copyWith({
    String? role,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? currentPageIndex,
    bool? isTermsAgreed,
    bool? isPrivacyAgreed,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    Map<String, Map<String, String>>? operatingHours,
    bool? is24Hours,
    String? resetTime,
  }) {
    return SignUpState(
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isTermsAgreed: isTermsAgreed ?? this.isTermsAgreed,
      isPrivacyAgreed: isPrivacyAgreed ?? this.isPrivacyAgreed,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      operatingHours: operatingHours ?? this.operatingHours,
      is24Hours: is24Hours ?? this.is24Hours,
      resetTime: resetTime ?? this.resetTime,
    );
  }
}

@riverpod
class SignUpNotifier extends _$SignUpNotifier {
  late final ProviderProfileService _profileService;

  // 電話番号認証の状態 (Firebaseコールバックでのみ使用する内部変数)
  String? _verificationId;
  int? _resendToken;

  // 内部変数
  User? _pendingUser;
  bool _isProgressLoaded = false; // 既存 _isInitialized と同じ役割
  bool _isDisposed = false; // 既存の notifyListeners() オーバーライドと同じ役割

  @override
  SignUpState build() {
    _profileService = ProviderProfileService(baseUrl: dotenv.env['API_URL']!);
    _isDisposed = false;
    ref.onDispose(() => _isDisposed = true);
    return const SignUpState();
  }

  // dispose後の書き込みを防止する共通ヘルパー
  // (既存の notifyListeners() オーバーライド[_isDisposedチェック]に相当。
  //  riverpod 2.6.1にはref.mountedが無いためonDisposeで立てるフラグを使う)
  void _updateState(SignUpState Function(SignUpState) updater) {
    if (_isDisposed) return;
    state = updater(state);
  }

  // --- セッター ---

  void setRole(String role) => _updateState((s) => s.copyWith(role: role));

  void setTermsAgreed(bool value) =>
      _updateState((s) => s.copyWith(isTermsAgreed: value));

  void setPrivacyAgreed(bool value) =>
      _updateState((s) => s.copyWith(isPrivacyAgreed: value));

  void reset() => _updateState((_) => const SignUpState());

  void setCurrentPageIndex(int index) =>
      _updateState((s) => s.copyWith(currentPageIndex: index));

  void setErrorMessage(String? msg) => _updateState(
      (s) => msg == null ? s.copyWith(clearErrorMessage: true) : s.copyWith(errorMessage: msg));

  void setLoading(bool loading) =>
      _updateState((s) => s.copyWith(isLoading: loading));

  void saveBusinessHours(
      Map<String, Map<String, String>> hours, bool is24h, String reset) {
    _updateState((s) => s.copyWith(operatingHours: hours, is24Hours: is24h, resetTime: reset));
  }

  // --- Logic Methods ---

  // SharedPreferencesから進捗を読み込む
  Future<int> loadSignUpProgress(String? widgetMode) async {
    if (_isProgressLoaded) return state.currentPageIndex;
    _isProgressLoaded = true;

    if (widgetMode == 'add_store') {
      return widgetMode == 'add_store' ? (state.role == 'staff' ? 6 : 7) : 0;
    }

    final prefs = await SharedPreferences.getInstance();

    // 未認証アカウントが残存している場合は即時サインアウトして最初からやり直し
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && !currentUser.emailVerified) {
      await FirebaseAuth.instance.signOut();
      await prefs.remove('signup_role');
      await prefs.remove('terms_agreed');
      await prefs.remove('signup_phone');
      _updateState((s) => s);
      return 0;
    }

    if (currentUser == null) {
      // 新規開始
      await prefs.remove('signup_role');
      await prefs.remove('terms_agreed');
      return 0;
    }

    // メール認証済みユーザーの再開フロー（電話番号・プロフィール未完了の場合）
    await currentUser.reload();
    _pendingUser = currentUser;

    bool isPhoneVerified = false;
    if (currentUser.phoneNumber != null && currentUser.phoneNumber!.isNotEmpty) {
      isPhoneVerified = true;
    }

    final savedRole = prefs.getString('signup_role');
    final savedTerms = prefs.getBool('terms_agreed') ?? false;
    final role = savedRole ?? state.role;

    _updateState((s) => s.copyWith(
          isEmailVerified: true,
          isPhoneVerified: isPhoneVerified,
          role: role,
          isTermsAgreed: savedTerms,
          isPrivacyAgreed: savedTerms,
        ));

    // メール認証済みなのでStep5はスキップ
    if (role == null) return 0;
    if (!savedTerms) return 1;
    if (!isPhoneVerified) return 6; // 電話番号認証
    return 8; // ユーザー情報
  }

  Future<void> saveSignUpProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.role != null) {
      await prefs.setString('signup_role', state.role!);
    }
    await prefs.setBool('terms_agreed', state.isTermsAgreed);
    // メモ: 電話番号は通常Viewのコントローラーで管理されるが、
    // アプリキル後も維持したい場合は内部バージョンを保存可能
  }

  Future<void> savePhoneProgress(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('signup_phone', phone);
  }

  // メールアドレスの重複チェック
  Future<bool> checkEmailDuplicate(String email) async {
    if (state.isLoading) return false; // 二重送信防止
    _updateState((s) => s.copyWith(isLoading: true, clearErrorMessage: true));

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
      _updateState((s) => s.copyWith(errorMessage: e.message));
      return false;
    } catch (e) {
      _updateState((s) => s.copyWith(errorMessage: 'エラーが発生しました: $e'));
      return false;
    } finally {
      _updateState((s) => s.copyWith(isLoading: false));
    }
  }

  // アカウント作成
  Future<bool> createAccountAndSendEmail(
      String email, String password, String mode) async {
    if (state.isLoading) return false; // 二重送信防止
    _updateState((s) => s.copyWith(isLoading: true, clearErrorMessage: true));

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
            await FirebaseAuth.instance.signOut(); // 認証完了前はセッション終了
          }
        } else {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'このメールアドレスは既に使用されています。',
          );
        }
      } else {
        try {
          final userCredential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          _pendingUser = userCredential.user;
          if (_pendingUser == null) throw Exception('アカウント作成に失敗しました。');

          await _pendingUser!.sendEmailVerification();
          await FirebaseAuth.instance.signOut(); // 認証完了前はセッション終了
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // クラッシュなどで未認証のFirebaseアカウントが残存している場合
            // サインインして認証状態を確認する
            try {
              final cred = await FirebaseAuth.instance
                  .signInWithEmailAndPassword(email: email, password: password);
              final existingUser = cred.user;
              if (existingUser != null && !existingUser.emailVerified) {
                // 未認証の残存アカウント → 認証メール再送してサインアウト
                _pendingUser = existingUser;
                await existingUser.sendEmailVerification();
                await FirebaseAuth.instance.signOut();
              } else {
                // 既に認証済みの本登録ユーザー → 重複エラーとして扱う
                await FirebaseAuth.instance.signOut();
                throw FirebaseAuthException(
                  code: 'email-already-in-use',
                  message: 'このメールアドレスは既に使用されています。',
                );
              }
            } catch (signInError) {
              if (signInError is FirebaseAuthException &&
                  signInError.code == 'email-already-in-use') {
                rethrow;
              }
              // パスワード不一致など → 本登録済みユーザーとして扱う
              throw FirebaseAuthException(
                code: 'email-already-in-use',
                message: 'このメールアドレスは既に使用されています。',
              );
            }
          } else {
            rethrow;
          }
        }
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        rethrow; // Viewでダイアログを処理させる
      } else if (e.code == 'weak-password') {
        _updateState((s) => s.copyWith(errorMessage: 'パスワードが弱すぎます。'));
      } else {
        _updateState((s) => s.copyWith(errorMessage: 'アカウント作成に失敗しました: ${e.message}'));
      }
      return false;
    } catch (e) {
      _updateState((s) => s.copyWith(errorMessage: 'エラーが発生しました: $e'));
      return false;
    } finally {
      setSignUpInProgress(false);
      _updateState((s) => s.copyWith(isLoading: false));
    }
  }

  // メール認証完了確認
  Future<bool> verifyEmailComplete(String emailInput, String passwordInput) async {
    if (state.isLoading) return false; // 二重送信防止
    _updateState((s) => s.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      setSignUpInProgress(true);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await currentUser.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null && refreshedUser.emailVerified) {
          _updateState((s) => s.copyWith(isEmailVerified: true));
          return true;
        }
      } else {
        // currentUser == null (signOut後) → サインインして認証状態を確認
        if (emailInput.isNotEmpty && passwordInput.isNotEmpty) {
          try {
            final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: emailInput.trim(),
              password: passwordInput,
            );
            if (cred.user != null) {
              await cred.user!.reload();
              if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
                _updateState((s) => s.copyWith(isEmailVerified: true));
                return true;
              } else {
                // サインイン成功したが未認証 → セッション終了してエラー表示
                await FirebaseAuth.instance.signOut();
                _updateState((s) =>
                    s.copyWith(errorMessage: 'メール認証がまだ完了していません。メールのリンクをクリックしてください。'));
                return false;
              }
            }
          } on FirebaseAuthException catch (e) {
            _updateState((s) => s.copyWith(errorMessage: 'ログインに失敗しました: ${e.message}'));
            return false;
          }
        }
        throw Exception('セッションが切れました。再度ログインしてください。');
      }
      return false;
    } catch (e) {
      _updateState((s) => s.copyWith(errorMessage: e.toString()));
      return false;
    } finally {
      setSignUpInProgress(false);
      _updateState((s) => s.copyWith(isLoading: false));
    }
  }

  // メール再送信
  Future<bool> resendEmailLink(
      String emailInput, String passwordInput, String mode) async {
    if (state.isLoading) return false; // 二重送信防止
    _updateState((s) => s.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      setSignUpInProgress(true);
      User? user;
      if (mode == 'resume' && FirebaseAuth.instance.currentUser != null) {
        user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          await FirebaseAuth.instance.signOut(); // 認証完了前はセッション終了
        }
      } else {
        // 静かに再ログインして認証メール再送
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailInput.trim(),
          password: passwordInput,
        );
        user = cred.user;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          await FirebaseAuth.instance.signOut(); // 認証完了前はセッション終了
        }
      }
      return true;
    } catch (e) {
      _updateState((s) => s.copyWith(errorMessage: 'メール送信失敗: $e'));
      return false;
    } finally {
      setSignUpInProgress(false);
      _updateState((s) => s.copyWith(isLoading: false));
    }
  }

  // --- 電話番号認証ロジック ---

  Future<bool> sendPhoneCode(String phoneNumber, String role) async {
    // メモ: バリデーションはViewで行われる
    _updateState((s) => s.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      setSignUpInProgress(true);
      final rawPhoneNumber = phoneNumber.trim();
      final internalNumberString =
          PhoneFormatter.formatPhoneNumberForInternal(rawPhoneNumber);
      final phoneNumberForFirebase = _formatPhoneNumber(internalNumberString);

      final completer = Completer<bool>();

      // iOS Simulator에서의 테스트 번호 인증을 위해 앱 검증(reCAPTCHA 우회) 비활성화
      await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumberForFirebase,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // 自動完了ロジックをここに記述可能だが、通常はcodeSentがメインフロー
          _updateState((s) => s.copyWith(isPhoneVerified: true));
        },
        verificationFailed: (FirebaseAuthException e) {
          String msg = '認証に失敗しました: ${e.message}';
          if (e.code == 'invalid-phone-number') msg = '電話番号の形式が正しくありません。';
          if (e.code == 'too-many-requests') {
            msg = '試行回数が多すぎます。しばらくしてから再度お試しください。';
          }
          _updateState((s) => s.copyWith(errorMessage: msg, isLoading: false));
          setSignUpInProgress(false);
          if (!completer.isCompleted) completer.complete(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _updateState((s) => s.copyWith(isLoading: false));
          // setSignUpInProgressはtrueのまま
          if (!completer.isCompleted) completer.complete(true);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );

      return completer.future;
    } catch (e) {
      setSignUpInProgress(false);
      _updateState((s) => s.copyWith(errorMessage: 'エラーが発生しました: $e', isLoading: false));
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
      _updateState((s) => s.copyWith(errorMessage: '6桁の認証コードを入力してください。'));
      return false;
    }

    _updateState((s) => s.copyWith(isLoading: true, clearErrorMessage: true));
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

      _updateState((s) => s.copyWith(isPhoneVerified: true));
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        _updateState((s) => s.copyWith(errorMessage: '認証コードが正しくありません。'));
      } else if (e.code == 'session-expired') {
        _updateState((s) => s.copyWith(errorMessage: '認証コードの有効期限が切れました。再度送信してください。'));
      } else {
        _updateState((s) => s.copyWith(errorMessage: '認証に失敗しました: ${e.message}'));
      }
      return false;
    } catch (e) {
      _updateState((s) => s.copyWith(errorMessage: 'エラーが発生しました: $e'));
      return false;
    } finally {
      setSignUpInProgress(false);
      _updateState((s) => s.copyWith(isLoading: false));
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
    _updateState((s) => s.copyWith(isLoading: true, clearErrorMessage: true));
    setSignUpInProgress(true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw const ApiException('ユーザー情報が見つかりません。再ログインしてください。');
      }

      final idToken = await currentUser.getIdToken();
      if (idToken == null) throw const ApiException('認証トークンの取得に失敗しました。');

      // Call API based on role/mode
      bool isAddingStore = mode == 'add_store';

      if (state.role == 'manager') {
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
            operatingHours: state.operatingHours,
            is24Hours: state.is24Hours,
            resetTime: state.resetTime,
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
      _updateState((s) => s.copyWith(errorMessage: e.message));
      return false;
    } catch (e) {
      _updateState((s) => s.copyWith(errorMessage: 'エラーが発生しました: $e'));
      return false;
    } finally {
      setSignUpInProgress(false);
      _updateState((s) => s.copyWith(isLoading: false));
    }
  }
}
