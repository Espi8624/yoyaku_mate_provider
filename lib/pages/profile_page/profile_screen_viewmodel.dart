import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoyaku_mate_provider/models/store_license.dart';
import 'package:yoyaku_mate_provider/models/store_profile.dart';
import 'package:yoyaku_mate_provider/models/user_profile.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';
import 'package:yoyaku_mate_provider/constants/staff_status.dart';

class ProfileScreenViewModel extends ChangeNotifier {
  final ProviderProfileService _profileService;
  String firebaseUid;

  String _mongoUserId = '';

  String get userId => firebaseUid;

  ProfileScreenViewModel({
    required ProviderProfileService profileService,
    required String userId,
    bool autoLoad = false,
  })  : _profileService = profileService,
        firebaseUid = userId;

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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String get storeId => _storeProfile?.id ?? '';

  // bool _isInitializedBySignUp = false;
  // void prepareForSignUp() {
  //   // print("--- [ViewModel] prepareForSignUp: SignUp 플래그 설정 ---");
  //   _isInitializedBySignUp = true;
  // }
  bool _isProfileIncomplete = false;
  bool get isProfileIncomplete => _isProfileIncomplete;

  // プロフィール情報初期化
  void clearProfile() {
    _userProfile = null;
    _storeProfile = null;
    _storeLicense = null;
    _myStores = [];
    _mongoUserId = '';
    _isProfileIncomplete = false;
    // _isInitializedBySignUp = false;
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
    _isProfileIncomplete = false;
    // _isInitializedBySignUp = true; // SignUpに初期化されていることを表示

    // print("  - _isInitializedBySignUp 플래그 설정됨");
    notifyListeners();
  }

  // Firebase UID変更時呼出
  void updateUser(String newUid) {
    // UIDが変わっていない場合は何もしない
    if (firebaseUid == newUid) {
      return;
    }

    firebaseUid = newUid;

    clearProfile();

    // 新しいUIDがあれば（ログインした場合）、データローディングを開始
    if (newUid.isNotEmpty) {
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
    // print("--- [ViewModel] loadProfiles 시작 ---");
    // print("  - firebaseUid: '$firebaseUid'");

    if (firebaseUid.isEmpty) {
      // print("   → firebaseUid가 비어있어 즉시 종료.");
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // print("   → (1) 가게 목록(fetchAllStores) API 호출 시작...");
      final myStoresResponse = await _profileService.fetchAllStores();
      // print("   → (2) 가게 목록 API 응답 받음.");

      if (myStoresResponse.containsKey('data') &&
          myStoresResponse['data'] is Map) {
        final outerData = myStoresResponse['data'] as Map<String, dynamic>;
        if (outerData.containsKey('data') && outerData['data'] is List) {
          final storesData = outerData['data'] as List;
          _myStores =
              storesData.map((data) => StoreProfile.fromJson(data)).toList();
          // print("   → (3) 가게 목록 파싱 완료: ${_myStores.length}개");

          // 店舗リストローディング後、ユーザープロフィールロード
          // print("   → (4) 사용자 프로필(_fetchInitialUserProfile) 호출 시작...");
          await _fetchInitialUserProfile();
          // print("   → (5) 사용자 프로필 호출 완료.");

          if (_userProfile != null) {
            // print(
            //     "   → (6) 성공: _userProfile이 정상적으로 설정되었습니다. (이름: ${_userProfile!.name})");
          } else {
            // print(
            //     "   → (6) 실패: _fetchInitialUserProfile 후에도 _userProfile이 여전히 null입니다!");
            throw ApiException(
                'User profile could not be loaded or parsed correctly.');
          }
        } else {
          throw ApiException('店舗リストデータ形式が異なります。(inner data)');
        }
      } else {
        throw ApiException('店舗リストデータ形式が異なります。(outer data)');
      }
    } on ApiException catch (e) {
      // ユーザーが見つからない場合は未完了フラグを立てる
      if (e.message.contains('User not found') ||
          e.message.contains('Status: 404')) {
        _isProfileIncomplete = true;
        // _errorMessageは設定しない (画面遷移するため)
      } else {
        _errorMessage = 'データローディング失敗: ${e.message}';
      }
      // print("   ✗ API 에러: ${e.message}");
    } catch (e) {
      _errorMessage = '予期しないエラーが発生しました。: $e';
      // print("   ✗ 예상치 못한 에러: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
      // print("--- [ViewModel] loadProfiles 종료 (isLoading: $_isLoading) ---");
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
    // print("     L-- [_fetchInitialUserProfile] 시작 (uid: $firebaseUid)");
    try {
      final userProfileResponse =
          await _profileService.fetchUserProfile(firebaseUid);
      // print("     L-- API 응답 받음.");

      if (userProfileResponse.containsKey('data') &&
          userProfileResponse['data'] is Map) {
        _userProfile = UserProfile.fromJson(
            userProfileResponse['data'] as Map<String, dynamic>);
        _mongoUserId = _userProfile?.id ?? '';
        // print("     L-- UserProfile 파싱 성공! (이름: ${_userProfile?.name})");
      } else {
        throw ApiException('無効なユーザーデータ形式です。');
      }
    } catch (e) {
      // print("     L-- ✗ 에러 발생: ${e.toString()}");
      rethrow; // 에러를 상위 함수(loadProfiles)로 다시 던짐
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

        // 更新された店舗情報を取得してローカルリストを更新
        final response = await _profileService.fetchStoreProfile(storeId);
        if (response.containsKey('data') && response['data'] is Map) {
          final updatedStore =
              StoreProfile.fromJson(response['data'] as Map<String, dynamic>);

          final index = _myStores.indexWhere((s) => s.id == storeId);
          if (index != -1) {
            _myStores[index] = updatedStore;
          }

          await selectStore(storeId);
        }
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

  Future<void> uploadUserImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);

    _setLoading(true);
    _errorMessage = null;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw ApiException('User not logged in.');
      final idToken = await currentUser.getIdToken(true);
      if (idToken == null) throw ApiException('Could not get auth token.');

      final updatedUserProfile =
          await _profileService.uploadUserImage(imageFile, idToken);

      _userProfile = updatedUserProfile;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> uploadStoreImage() async {
    if (_storeProfile == null) {
      _errorMessage = "店舗が選択されていません。";
      notifyListeners();
      return;
    }

    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);

    _setLoading(true);
    _errorMessage = null;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw ApiException('User not logged in.');
      final idToken = await currentUser.getIdToken(true);
      if (idToken == null) throw ApiException('Could not get auth token.');

      final updatedStoreProfile = await _profileService.uploadStoreImage(
          imageFile, _storeProfile!.id, idToken);

      _storeProfile = updatedStoreProfile;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
    } finally {
      _setLoading(false);
    }
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

  Future<bool> joinStore(String storeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileService.joinStore(storeId);
      _successMessage = "参加リクエストを送信しました。承認をお待ちください。";
      await loadProfiles();
      return true;
    } on ApiException catch (e) {
      _errorMessage = "参加リクエスト送信失敗: ${e.message}";
      return false;
    } catch (e) {
      _errorMessage = "予期しないエラーが発生しました: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Staff Management Logic ---

  List<dynamic> _staffList = [];
  List<dynamic> get staffList => _staffList;

  Future<void> fetchStoreStaff(String storeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final staff = await _profileService.fetchStoreStaff(storeId);
      _staffList = staff;
    } on ApiException catch (e) {
      _errorMessage = "スタッフリスト取得失敗: ${e.message}";
    } catch (e) {
      _errorMessage = "予期しないエラーが発生しました: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStoreStaffStatus(
      String storeId, String staffId, String status) async {
    // ローディング状態にすると画面が再描画されてリストが消える可能性があるため、
    // ここではあえて _isLoading = true にせず、バックグラウンドで処理するか、
    // あるいは個別のローディング状態を持つのが理想ですが、
    // 簡易的に全体ローディングを使います（UX要件に応じて調整）。
    // _isLoading = true;
    // notifyListeners();

    try {
      await _profileService.updateStoreStaffStatus(storeId, staffId, status);
      _successMessage =
          status == StaffStatus.approved ? 'スタッフを承認しました' : 'スタッフを拒否しました';

      // リストを再取得して最新状態にする
      await fetchStoreStaff(storeId);
      return true;
    } on ApiException catch (e) {
      _errorMessage = "ステータス更新失敗: ${e.message}";
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "予期しないエラーが発生しました: $e";
      notifyListeners();
      return false;
    }
  }
}
