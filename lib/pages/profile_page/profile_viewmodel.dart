import 'package:flutter/material.dart';
import '../../models/store_profile.dart';
import '../../models/user_profile.dart';
import '../../services/api_exception.dart';
import '../../services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProviderProfileService _profileService;

  final String firebaseUid;

  String _mongoUserId = '';

  ProfileViewModel({
    required ProviderProfileService profileService,
    required String userId, // 生成者では Firebase UID を取得
  })  : _profileService = profileService,
        firebaseUid = userId;

  // --- State ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  StoreProfile? _storeProfile;
  StoreProfile? get storeProfile => _storeProfile;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _storeId = '';
  String get storeId => _storeId;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // プロフィール情報初期化
  void clearProfile() {
    _userProfile = null;
    _storeProfile = null;
    _mongoUserId = '';
    _storeId = '';
    notifyListeners();
  }

  Future<void> loadProfiles() async {
    // 既にデータが存在している場合再ロードしない
    if (_userProfile != null) return;

    _setLoading(true);
    _errorMessage = null;
    try {
      // Firebase UID でユーザー情報を取得
      final userProfileResponse =
          await _profileService.fetchUserProfile(firebaseUid);

      if (!userProfileResponse.containsKey('data') ||
          userProfileResponse['data'] == null) {
        throw ApiException('無効なユーザーデータ形式です。');
      }
      final userData = userProfileResponse['data'];
      if (userData is! Map<String, dynamic>) {
        throw ApiException('無効なユーザーデータ形式です。');
      }

      // モデル Object を生成し、MongoDB ID と Store ID を ViewModel Status に保存する
      _userProfile = UserProfile.fromJson(userData);
      _mongoUserId = _userProfile?.id ?? '';
      final fetchedStoreId = _userProfile?.storeId;

      if (fetchedStoreId != null && fetchedStoreId.isNotEmpty) {
        _storeId = fetchedStoreId;
      } else {
        if (_userProfile?.role == 'manager') {
          throw ApiException('ユーザー情報に店舗IDが含まれていません。');
        }
      }

      // 管理者及び storeId がある場合、店舗プロフィールを取得
      if (_userProfile?.role == 'manager' && _storeId.isNotEmpty) {
        final storeProfileResponse =
            await _profileService.fetchStoreProfile(_storeId);

        if (!storeProfileResponse.containsKey('data') ||
            storeProfileResponse['data'] == null) {
          throw ApiException('無効な店舗データ形式です。');
        }
        final storeData = storeProfileResponse['data'];
        if (storeData is! Map<String, dynamic>) {
          throw ApiException('無効な店舗データ形式です。');
        }

        _storeProfile = StoreProfile.fromJson(storeData);
      }
    } on ApiException catch (e) {
      _errorMessage = 'データローディング失敗: ${e.message}';
    } catch (e) {
      _errorMessage = '予期せぬエラーが発生しました: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfileField(
      {String? userFieldKey,
      String? storeFieldKey,
      required String value}) async {
    _setLoading(true);
    _errorMessage = null;
    bool success = false;
    try {
      if (userFieldKey != null) {
        // ユーザープロフィール更新時は MongoDB ID を使用
        if (_mongoUserId.isEmpty) throw ApiException('ユーザーIDが見つかりません。');
        await _profileService
            .updateUserProfile(_mongoUserId, {userFieldKey: value});
      } else if (storeFieldKey != null && _storeId.isNotEmpty) {
        // 店舗プロフィール更新時は Store ID を使用
        await _profileService
            .updateStoreProfile(_storeId, {storeFieldKey: value});
      }

      // 更新成功後、最新データを再取得するため既存データを初期化
      clearProfile();
      await loadProfiles();
      success = true;
    } on ApiException catch (e) {
      _errorMessage = '更新に失敗しました: ${e.message}';
    } catch (e) {
      _errorMessage = '予期せぬエラーが発生しました: $e';
    } finally {
      _setLoading(false);
    }
    return success;
  }
}
