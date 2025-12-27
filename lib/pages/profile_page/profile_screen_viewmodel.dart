import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoyaku_mate_provider/models/store_license.dart';
import 'package:yoyaku_mate_provider/models/store_profile.dart';
import 'package:yoyaku_mate_provider/models/store_settings.dart';
import 'package:yoyaku_mate_provider/models/user_profile.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';
import 'package:yoyaku_mate_provider/services/store_settings_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreenViewModel extends ChangeNotifier {
  final ProviderProfileService _profileService;
  final StoreSettingsService _settingsService;
  String firebaseUid;

  String _mongoUserId = '';

  String get userId => firebaseUid;

  ProfileScreenViewModel({
    required ProviderProfileService profileService,
    required StoreSettingsService settingsService,
    required String userId,
    bool autoLoad = false,
  })  : _profileService = profileService,
        _settingsService = settingsService,
        firebaseUid = userId {
    _loadAppInfo();
  }

  // --- App Info ---
  String _appVersion = '';
  String get appVersion => _appVersion;

  String _buildNumber = '';
  String get buildNumber => _buildNumber;

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      notifyListeners();
    } catch (e) {
      // print("Error loading app info: $e");
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

  StoreSettings? _storeSettings;
  StoreSettings? get storeSettings => _storeSettings;

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

  int _profileTabIndex = 0;
  int get profileTabIndex => _profileTabIndex;

  void setProfileTabIndex(int index) {
    if (_profileTabIndex != index) {
      _profileTabIndex = index;
      notifyListeners();
    }
  }

  // プロフィール情報初期化
  void clearProfile() {
    _userProfile = null;
    _storeProfile = null;
    _storeLicense = null;
    _myStores = [];
    _mongoUserId = '';
    _isProfileIncomplete = false;
    _profileTabIndex = 0; // Reset tab index on clear
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
    if (!_myStores.any((store) => store.id == newStore.id)) {
      _myStores.add(newStore);

      // 現在選択された店舗初期化
      _storeProfile = null;
      _storeLicense = null;

      notifyListeners();
    }
  }

  // 店舗選択のみを解除するメソッド
  void clearStoreSelection() {
    _storeProfile = null;
    _storeLicense = null;
    _storeSettings = null;
    notifyListeners();
  }

  Future<void> loadProfiles({bool forceRefresh = false}) async {
    if (firebaseUid.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
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

          // 店舗リストローディング後、ユーザープロフィールロード
          await _fetchInitialUserProfile();

          if (_userProfile == null) {
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
    } catch (e) {
      _errorMessage = '予期しないエラーが発生しました。: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> selectStore(String storeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 既に持っているmyStoresリストから選択された店舗情報を即座に探索
      final selectedStore = _myStores.firstWhere(
        (store) => store.id == storeId,
        orElse: () => throw ApiException("選択された店舗をローカルリストから検索できませんでした。"),
      );

      // 探した店情報を_storeProfileに直接割当（API呼出なし)
      _storeProfile = selectedStore;

      try {
        final storeLicenseResponse =
            await _profileService.fetchStoreLicense(storeId);

        if (storeLicenseResponse.containsKey('data') &&
            storeLicenseResponse['data'] is Map) {
          _storeLicense = StoreLicense.fromJson(
              storeLicenseResponse['data'] as Map<String, dynamic>);
        }
      } catch (e) {
        // ライセンス取得失敗（404またはネットワークエラー）
        // 店舗に入るのを妨げない。ライセンスをnullに設定するだけ
        _storeLicense = null;
      }

      // Store Settings Fetch
      try {
        _storeSettings = await _settingsService.fetchStoreSettings(storeId);
      } catch (e) {
        // Settings取得失敗（404またはネットワークエラー）
        // 店舗に入るのを妨げない。Settingsをnullに設定するだけ
        _storeSettings = null;
      }

      return true;
    } on ApiException catch (e) {
      _errorMessage = '店舗詳細情報の読み込みに失敗しました: ${e.message}';
      _storeProfile = null; // 失敗時選択されたプロフィールも初期化

      return false;
    } catch (e) {
      _errorMessage = '予期せぬエラーが発生しました: $e';
      _storeProfile = null; // 失敗時選択されたプロフィールも初期化

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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

        // Optimistic Update: UIを即時反映させる
        if (_userProfile != null) {
          if (userFieldKey == 'user_name' || userFieldKey == 'name') {
            _userProfile = _userProfile!.copyWith(name: value);
          } else if (userFieldKey == 'email') {
            _userProfile = _userProfile!.copyWith(email: value);
          } else if (userFieldKey == 'phone_number') {
            _userProfile = _userProfile!.copyWith(phone_number: value);
          }
          notifyListeners();
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
            final oldStore = _myStores[index];
            final newStore = StoreProfile(
              id: updatedStore.id,
              name: updatedStore.name,
              address: updatedStore.address,
              phone_number: updatedStore.phone_number,
              bizNumber: updatedStore.bizNumber,
              storeImageUrl: updatedStore.storeImageUrl,
              verificationStatus: updatedStore.verificationStatus ??
                  oldStore.verificationStatus,
              staffStatus: updatedStore.staffStatus ?? oldStore.staffStatus,
            );
            _myStores[index] = newStore;
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

      // レスポンスにverificationStatusとstaffStatusが欠けている場合は、保持する
      if (_storeProfile != null) {
        _storeProfile = StoreProfile(
          id: updatedStoreProfile.id,
          name: updatedStoreProfile.name,
          address: updatedStoreProfile.address,
          phone_number: updatedStoreProfile.phone_number,
          bizNumber: updatedStoreProfile.bizNumber,
          storeImageUrl: updatedStoreProfile.storeImageUrl,
          verificationStatus: updatedStoreProfile.verificationStatus ??
              _storeProfile!.verificationStatus,
          staffStatus:
              updatedStoreProfile.staffStatus ?? _storeProfile!.staffStatus,
        );
      } else {
        _storeProfile = updatedStoreProfile;
      }
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

      // アップロード成功後、最新の店舗情報を取得してローカルリスト(myStores)を更新
      final response = await _profileService.fetchStoreProfile(storeId);

      if (response.containsKey('data') && response['data'] is Map) {
        // アップロード成功後、最新の店舗情報を取得してローカルリスト(myStores)を更新
        final updatedStore =
            StoreProfile.fromJson(response['data'] as Map<String, dynamic>);

        final index = _myStores.indexWhere((s) => s.id == storeId);
        if (index != -1) {
          final oldStore = _myStores[index];
          final newStore = StoreProfile(
            id: updatedStore.id,
            name: updatedStore.name,
            address: updatedStore.address,
            phone_number: updatedStore.phone_number,
            bizNumber: updatedStore.bizNumber,
            storeImageUrl: updatedStore.storeImageUrl,
            verificationStatus:
                updatedStore.verificationStatus ?? oldStore.verificationStatus,
            staffStatus: updatedStore.staffStatus ?? oldStore.staffStatus,
          );
          _myStores[index] = newStore;
        }
      }

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

  Future<void> updateStoreSettings(StoreSettings newSettings) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _settingsService.updateStoreSettings(newSettings);
      _storeSettings = newSettings;
      _successMessage = '設定が保存されました';
    } catch (e) {
      _errorMessage = '設定の保存に失敗しました: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
