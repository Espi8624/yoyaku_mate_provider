import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/models/store_license.dart';
import 'package:yoyaku_mate_provider/models/store_profile.dart';
import 'package:yoyaku_mate_provider/models/user_profile.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';

class ProfileScreenViewModel extends ChangeNotifier {
  final ProviderProfileService _profileService;
  final String firebaseUid;

  String _mongoUserId = '';

  ProfileScreenViewModel({
    required ProviderProfileService profileService,
    required String userId,
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

  String get storeId => _storeProfile?.id ?? '';

  // プロフィール情報初期化
  void clearProfile() {
    _userProfile = null;
    _storeProfile = null;
    _storeLicense = null;
    _myStores = [];
    _mongoUserId = '';
    notifyListeners();
  }

  Future<void> loadProfiles({bool forceRefresh = false}) async {
    if (firebaseUid.isEmpty) return;
    // forceRefreshがfalseのときのみ重複ロード防止ロジックを実行
    if (!forceRefresh && _myStores.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    // forceRefresh時、UIが即座にローディング状態になるように通知
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
          await _fetchInitialUserProfile();
        } else {
          throw ApiException('無効な店舗リストのデータ形式です。(inner data)');
        }
      } else {
        throw ApiException('無効な店舗リストのデータ形式です。(outer data)');
      }
    } on ApiException catch (e) {
      _errorMessage = 'データローディング失敗: ${e.message}';
    } catch (e) {
      _errorMessage = '予期せぬエラーが発生しました: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectStore(String storeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (_userProfile == null) {
        await _fetchInitialUserProfile();
      }
      final responses = await Future.wait([
        _profileService.fetchStoreProfile(storeId),
        _profileService.fetchStoreLicense(storeId),
      ]);
      final storeProfileResponse = responses[0];
      final storeLicenseResponse = responses[1];
      if (storeProfileResponse.containsKey('data') &&
          storeProfileResponse['data'] is Map) {
        _storeProfile = StoreProfile.fromJson(
            storeProfileResponse['data'] as Map<String, dynamic>);
      } else {
        throw ApiException('無効な店舗データ形式です。');
      }
      if (storeLicenseResponse.containsKey('data') &&
          storeLicenseResponse['data'] is Map) {
        _storeLicense = StoreLicense.fromJson(
            storeLicenseResponse['data'] as Map<String, dynamic>);
      } else {
        throw ApiException('無効な店舗ライセンスデータ形式です。');
      }
    } on ApiException catch (e) {
      _errorMessage = '店舗詳細情報の読み込みに失敗しました: ${e.message}';
    } catch (e) {
      _errorMessage = '予期せぬエラーが発生しました: $e';
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

  Future<bool> updateProfileField(
      {String? userFieldKey,
      String? storeFieldKey,
      required String value}) async {
    _isLoading = true;
    notifyListeners();
    _errorMessage = null;
    bool success = false;
    try {
      if (userFieldKey != null) {
        if (_mongoUserId.isEmpty) throw ApiException('ユーザーIDが見つかりません。');
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
}
