import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/models/store_license.dart';
import 'package:yoyaku_mate_provider/models/store_profile.dart';
import 'package:yoyaku_mate_provider/models/user_profile.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';

class ProfileScreenViewModel extends ChangeNotifier {
  final ProviderProfileService _profileService;
  String firebaseUid;

  String _mongoUserId = '';

  String get userId => firebaseUid;

  ProfileScreenViewModel({
    required ProviderProfileService profileService,
    required String userId,
    bool autoLoad = true,
  })  : _profileService = profileService,
        firebaseUid = userId {
    // print("--- [ViewModel] 새로운 인스턴스 생성됨! ---");
    // print("  - 해시코드: $hashCode");
    // print("  - 할당된 firebaseUid: '$firebaseUid'");
    // print("  - autoLoad: $autoLoad");

    // autoLoadがtrueのときのみ自動でプロフィールをロード
    if (autoLoad && firebaseUid.isNotEmpty) {
      loadProfiles();
    }
  }

  // --- State ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  List<StoreProfile> _myStores = [];
  List<StoreProfile> get myStores => _myStores;

  StoreProfile? _storeProfile;
  StoreProfile? get storeProfile => _storeProfile;

  StoreLicense? _storeLicense;
  StoreLicense? get storeLicense => _storeLicense;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // snackbar表示のための状態変数
  String? _successMessage;
  String? get successMessage => _successMessage;

  void clearSuccessMessage() {
    _successMessage = null;
  }

  String get storeId => _storeProfile?.id ?? '';

  bool _isInitializedBySignUp = false;
  void prepareForSignUp() {
    // print("--- [ViewModel] prepareForSignUp: SignUp 플래그 설정 ---");
    _isInitializedBySignUp = true;
  }

  // プロフィール情報初期化
  void clearProfile() {
    _userProfile = null;
    _storeProfile = null;
    _storeLicense = null;
    _myStores = [];
    _mongoUserId = '';
    _isInitializedBySignUp = false;
    notifyListeners();
  }

  // SignUp完了後、データ注入用メソッド
  void setInitialData(UserProfile user, List<StoreProfile> stores) {
    // print("--- [ViewModel] setInitialData 호출됨 ---");
    // print("  - User: ${user.name}");
    // print("  - Stores: ${stores.length}개");

    _userProfile = user;
    _mongoUserId = user.id;
    _myStores = stores;
    _isLoading = false;
    _errorMessage = null;
    _isInitializedBySignUp = true; // SignUpに初期化されていることを表示

    // print("  - _isInitializedBySignUp 플래그 설정됨");
    notifyListeners();
  }

  // Firebase UID変更時呼出
  void updateUser(String newUid, {bool autoLoad = true}) {
    // print("--- [ViewModel] updateUser 호출됨 ---");
    // print("  - 기존 UID: '$firebaseUid'");
    // print("  - 새로운 UID: '$newUid'");
    // print("  - autoLoad: $autoLoad");
    // print("  - _isInitializedBySignUp: $_isInitializedBySignUp");

    if (firebaseUid == newUid) {
      // print("  → UID가 동일하여 아무 작업도 하지 않습니다.");
      return;
    }

    firebaseUid = newUid;

    // SignUp直後ならデータを消さない
    if (!_isInitializedBySignUp) {
      clearProfile();
    }

    if (autoLoad && firebaseUid.isNotEmpty && !_isInitializedBySignUp) {
      // print("  → 프로필 자동 로딩을 시작합니다.");
      _isLoading = true;
      notifyListeners();
      loadProfiles();
    }
  }

  void addStore(StoreProfile newStore) {
    // print("--- [ViewModel] addStore 호출됨 ---");
    // print("  - 추가할 가게: ${newStore.storeName}");

    if (!_myStores.any((store) => store.id == newStore.id)) {
      _myStores.add(newStore);
      // print("  → 가게가 추가되었습니다. 총 ${_myStores.length}개");

      // 現在選択された店舗初期化
      _storeProfile = null;
      _storeLicense = null;

      notifyListeners();
    } else {
      // print("  → 이미 존재하는 가게입니다.");
    }
  }

  Future<void> loadProfiles({bool forceRefresh = false}) async {
    // print("--- [ViewModel] loadProfiles 호출됨 ---");
    // print("  - firebaseUid: '$firebaseUid'");
    // print("  - forceRefresh: $forceRefresh");
    // print("  - _isInitializedBySignUp: $_isInitializedBySignUp");
    // print("  - _myStores.length: ${_myStores.length}");
    // print("  - _userProfile: ${_userProfile?.name ?? 'null'}");

    // SignUp直後、初期化されてたら自動ローディングをスキップ
    if (_isInitializedBySignUp && !forceRefresh) {
      // print("   → SignUpPage에 의해 초기화되었으므로 자동 로딩을 건너뜁니다.");
      _isInitializedBySignUp = false; // flag　reset
      return;
    }

    if (firebaseUid.isEmpty) {
      // print("   → firebaseUid가 비어있어 건너뜁니다.");
      return;
    }

    // データが既に存在し、forceRefreshがfalseならスキップ
    if (!forceRefresh && _myStores.isNotEmpty && _userProfile != null) {
      // print("   → 데이터가 이미 존재하여 건너뜁니다.");
      return;
    }
    // print("   → 프로필 로딩을 시작합니다.");

    _isLoading = true;
    _errorMessage = null;

    if (forceRefresh) {
      _myStores = [];
      _storeProfile = null;
      _storeLicense = null;
    }

    notifyListeners();

    try {
      final myStoresResponse = await _profileService.fetchAllStores();

      if (myStoresResponse.containsKey('data') &&
          myStoresResponse['data'] is Map) {
        final outerData = myStoresResponse['data'] as Map<String, dynamic>;
        if (outerData.containsKey('data') && outerData['data'] is List) {
          final storesData = outerData['data'] as List;
          _myStores =
              storesData.map((data) => StoreProfile.fromJson(data)).toList();
          _storeProfile = null;
          _storeLicense = null;

          // print("   → 가게 목록 로딩 완료: ${_myStores.length}개");

          // 店舗リストローディング成功後、使用者プロフィールもロード
          await _fetchInitialUserProfile();
          // print("   → 사용자 프로필 로딩 완료");
        } else {
          throw ApiException('無効な店舗リストのデータ形式です。(inner data)');
        }
      } else {
        throw ApiException('無効な店舗リストのデータ形式です。(outer data)');
      }
    } on ApiException catch (e) {
      _errorMessage = 'データローディング失敗: ${e.message}';
      // print("   ✗ API 에러: ${e.message}");
    } catch (e) {
      _errorMessage = '予期せぬエラーが発生しました: $e';
      // print("   ✗ 예상치 못한 에러: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
      // print("   → loadProfiles 완료");
    }
  }

  Future<bool> selectStore(String storeId) async {
    // print("--- [ViewModel] selectStore 호출됨 (개선된 방식) ---");
    // print("  - 선택된 storeId: '$storeId'");

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 既に持っているmyStoresリストから選択された店舗情報を即座に探索
      final selectedStore = _myStores.firstWhere(
        (store) => store.id == storeId,
        orElse: () => throw ApiException("選択された店舗をローカルリストから検索できませんでした。"),
      );

      // 探した店情報を_storeProfileに直接割当（API呼出なし）
      _storeProfile = selectedStore;
      // print("  → 로컬에서 가게 찾음: ${_storeProfile?.name}");

      // print("  → 가게 인증서 정보 로딩 시작...");
      final storeLicenseResponse =
          await _profileService.fetchStoreLicense(storeId);

      if (storeLicenseResponse.containsKey('data') &&
          storeLicenseResponse['data'] is Map) {
        _storeLicense = StoreLicense.fromJson(
            storeLicenseResponse['data'] as Map<String, dynamic>);
        // print("  → 가게 인증서 정보 로딩 완료");
      } else {
        throw ApiException('無効な店舗ライセンスデータ形式です。');
      }

      _successMessage = "'${_storeProfile?.name}' 店舗が選択されました。";

      return true;
    } on ApiException catch (e) {
      _errorMessage = '店舗詳細情報の読み込みに失敗しました: ${e.message}';
      _storeProfile = null; // 失敗時選択されたプロフィールも初期化
      // print("  ✗ API 에러: ${e.message}");

      return false;
    } catch (e) {
      _errorMessage = '予期せぬエラーが発生しました: $e';
      _storeProfile = null; // 失敗時選択されたプロフィールも初期化
      // print("  ✗ 예상치 못한 에러: $e");

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
      // print("--- [ViewModel] selectStore 완료 ---");
    }
  }

  Future<void> _fetchInitialUserProfile() async {
    if (firebaseUid.isEmpty) return;

    try {
      final userProfileResponse =
          await _profileService.fetchUserProfile(firebaseUid);

      if (userProfileResponse.containsKey('data') &&
          userProfileResponse['data'] is Map) {
        _userProfile = UserProfile.fromJson(
            userProfileResponse['data'] as Map<String, dynamic>);
        _mongoUserId = _userProfile?.id ?? '';
      } else {
        throw ApiException('無効なユーザーデータ形式です。');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateProfileField({
    String? userFieldKey,
    String? storeFieldKey,
    required String value,
  }) async {
    _isLoading = true;
    notifyListeners();
    _errorMessage = null;
    bool success = false;

    try {
      if (userFieldKey != null) {
        if (_mongoUserId.isEmpty) {
          throw ApiException('ユーザーIDが見つかりません。');
        }
        await _profileService
            .updateUserProfile(_mongoUserId, {userFieldKey: value});
        await _fetchInitialUserProfile();
      } else if (storeFieldKey != null && storeId.isNotEmpty) {
        await _profileService
            .updateStoreProfile(storeId, {storeFieldKey: value});
        await selectStore(storeId);
      }
      success = true;
    } on ApiException catch (e) {
      _errorMessage = '更新に失敗しました: ${e.message}';
    } catch (e) {
      _errorMessage = '予期せぬエラーが発生しました: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return success;
  }

  Future<bool> uploadStoreLicense(File imageFile) async {
    if (storeId.isEmpty) {
      _errorMessage = "アップロードする店舗が選択されてません。";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileService.uploadLicenseImage(storeId, imageFile);
      await selectStore(storeId);
      return true;
    } on ApiException catch (e) {
      _errorMessage = "アップロード失敗: ${e.message}";
      return false;
    } catch (e) {
      _errorMessage = "予期しないエラーが発生しました。: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
