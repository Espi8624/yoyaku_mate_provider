// アプリ全体のセッション状態 (Riverpod)
//
// ProfileScreenViewModel(旧 provider/MVVM)からの全面移行。
// ログインユーザー・所有店舗一覧・選択中の店舗・店舗設定/ライセンスは
// profile_page 固有ではなくアプリ全体で共有されるセッション状態のため、
// ページ配下ではなく lib/providers/ に置く。
//
// 設計方針:
// - 状態は単一責任ごとに provider を分離 (旧ViewModelは1クラスに8種の状態を保持していた)
// - ローディング/エラーは AsyncValue で自動表現 (_isLoading/_errorMessage の手動管理を廃止)
// - 成功/失敗メッセージは共有状態に持たず、呼び出し側で即時Toast/SnackBar表示
// - 更新系アクションは ProfileActions/StoreActions (状態を持たないNotifier) に集約し、
//   成功時は関連providerをinvalidateして宣言的に再取得させる
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yoyaku_mate_provider/models/store_license.dart';
import 'package:yoyaku_mate_provider/models/store_profile.dart';
import 'package:yoyaku_mate_provider/models/store_settings.dart';
import 'package:yoyaku_mate_provider/models/user_profile.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';
import 'package:yoyaku_mate_provider/services/shift_table_service.dart';
import 'package:yoyaku_mate_provider/services/store_settings_service.dart';

part 'session_providers.g.dart';

// --- Services (stateless) ---

@riverpod
ProviderProfileService profileService(Ref ref) {
  return ProviderProfileService(baseUrl: dotenv.env['API_URL'] ?? '');
}

@riverpod
StoreSettingsService storeSettingsService(Ref ref) {
  return StoreSettingsService(baseUrl: dotenv.env['API_URL'] ?? '');
}

@riverpod
ShiftTableService shiftTableService(Ref ref) {
  return ShiftTableService(baseUrl: dotenv.env['API_URL'] ?? '');
}

// --- 認証状態 ---

@riverpod
Stream<User?> firebaseUser(Ref ref) {
  return FirebaseAuth.instance.authStateChanges();
}

// --- アプリ情報 ---

@riverpod
Future<PackageInfo> appInfo(Ref ref) {
  return PackageInfo.fromPlatform();
}

// --- ユーザープロフィール ---

@riverpod
Future<UserProfile> userProfile(Ref ref) async {
  final uid = ref.watch(firebaseUserProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) {
    throw const ApiException('ユーザーがログインしていません。');
  }
  final service = ref.watch(profileServiceProvider);

  try {
    final res = await service.fetchUserProfile(uid);
    if (!(res.containsKey('data') && res['data'] is Map)) {
      throw const ApiException('無効なユーザーデータ形式です。');
    }
    return UserProfile.fromJson(res['data'] as Map<String, dynamic>);
  } on ApiException catch (e) {
    // ユーザーがまだ登録されていない場合 (サインアップ未完了) は専用の例外に変換し、
    // 呼び出し側が「エラー」ではなく「サインアップへ誘導」として扱えるようにする
    if (e.message.contains('User not found') ||
        e.message.contains('Status: 404')) {
      throw ProfileNotFoundException(e.message, statusCode: e.statusCode);
    }
    rethrow;
  }
}

// --- 所有店舗一覧 ---

@riverpod
Future<List<StoreProfile>> myStores(Ref ref) async {
  // ログインユーザーが変わったら自動再取得
  ref.watch(firebaseUserProvider);
  final service = ref.watch(profileServiceProvider);

  final res = await service.fetchAllStores();
  if (!(res.containsKey('data') && res['data'] is Map)) {
    throw const ApiException('店舗リストデータ形式が異なります。(outer data)');
  }
  final outerData = res['data'] as Map<String, dynamic>;
  if (!outerData.containsKey('data')) {
    throw const ApiException('店舗リストデータ形式が異なります。(inner data key)');
  }
  final storesList = outerData['data'];
  if (storesList == null) return [];
  if (storesList is! List) {
    throw const ApiException('店舗リストデータ形式が異なります。(inner data list form)');
  }
  return storesList.map((data) => StoreProfile.fromJson(data)).toList();
}

// --- 選択中の店舗 ---

@riverpod
class SelectedStoreId extends _$SelectedStoreId {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

@riverpod
StoreProfile? selectedStoreProfile(Ref ref) {
  final id = ref.watch(selectedStoreIdProvider);
  if (id == null) return null;

  final stores = ref.watch(myStoresProvider).valueOrNull ?? const [];
  for (final store in stores) {
    if (store.id == id) return store;
  }
  return null;
}

// --- 店舗ライセンス/設定 (店舗ごと) ---

@riverpod
Future<StoreLicense?> storeLicense(Ref ref, {required String storeId}) async {
  final service = ref.watch(profileServiceProvider);
  try {
    final res = await service.fetchStoreLicense(storeId);
    if (res.containsKey('data') && res['data'] is Map) {
      return StoreLicense.fromJson(res['data'] as Map<String, dynamic>);
    }
    return null;
  } catch (_) {
    // ライセンス取得失敗 (404またはネットワークエラー) で店舗への進入自体は妨げない
    return null;
  }
}

@riverpod
Future<StoreSettings?> storeSettings(Ref ref, {required String storeId}) async {
  final service = ref.watch(storeSettingsServiceProvider);
  try {
    return await service.fetchStoreSettings(storeId);
  } catch (_) {
    return null;
  }
}

// --- ユーザープロフィール関連アクション ---

@riverpod
class ProfileActions extends _$ProfileActions {
  @override
  void build() {}

  // pickImage連打でPHPickerViewControllerが二重に起動し、
  // ネイティブ側の画面がフリーズするのを防ぐためのガード
  bool _isPickingImage = false;

  Future<void> updateUserProfileFields(Map<String, dynamic> updates) async {
    final mongoUserId = ref.read(userProfileProvider).valueOrNull?.id;
    if (mongoUserId == null || mongoUserId.isEmpty) {
      throw const ApiException('ユーザーIDが見つかりません。');
    }

    // フロント側のフィールド名 -> バックエンドのフィールド名にマッピング
    final backendUpdates = <String, dynamic>{};
    updates.forEach((key, value) {
      if (key == 'name') {
        backendUpdates['user_name'] = value;
      } else if (key == 'name_furigana') {
        backendUpdates['user_name_furigana'] = value;
      } else if (key == 'email') {
        backendUpdates['email'] = value;
      } else if (key == 'phone_number') {
        backendUpdates['phone'] = value;
      } else {
        backendUpdates[key] = value;
      }
    });

    final service = ref.read(profileServiceProvider);
    await service.updateUserProfile(mongoUserId, backendUpdates);
    ref.invalidate(userProfileProvider);
  }

  Future<void> updateUserProfileField(String fieldKey, String value) {
    return updateUserProfileFields({fieldKey: value});
  }

  Future<void> uploadUserImage() async {
    if (_isPickingImage) return; // 連打による二重起動を無視
    _isPickingImage = true;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
        requestFullMetadata: false, // iOSシミュレーター停止バグ防止
      );
      if (pickedFile == null) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw const ApiException('User not logged in.');
      final idToken = await currentUser.getIdToken(true);
      if (idToken == null) {
        throw const ApiException('Could not get auth token.');
      }

      final service = ref.read(profileServiceProvider);
      await service.uploadUserImage(File(pickedFile.path), idToken);
      ref.invalidate(userProfileProvider);
    } finally {
      _isPickingImage = false;
    }
  }
}

// --- 店舗関連アクション ---

@riverpod
class StoreActions extends _$StoreActions {
  @override
  void build() {}

  // pickImage連打でPHPickerViewControllerが二重に起動し、
  // ネイティブ側の画面がフリーズするのを防ぐためのガード
  bool _isPickingImage = false;

  void selectStore(String storeId) {
    ref.read(selectedStoreIdProvider.notifier).select(storeId);
  }

  void clearSelection() {
    ref.read(selectedStoreIdProvider.notifier).select(null);
  }

  Future<void> joinStore(String storeId) async {
    final service = ref.read(profileServiceProvider);
    await service.joinStore(storeId);
    ref.invalidate(myStoresProvider);
  }

  // 新規作成された店舗を一覧に反映し、そのまま選択状態にする
  void addStore(StoreProfile store) {
    ref.invalidate(myStoresProvider);
    ref.read(selectedStoreIdProvider.notifier).select(store.id);
  }

  Future<void> updateStoreProfileField(
      String storeId, String fieldKey, String value) async {
    final service = ref.read(profileServiceProvider);
    await service.updateStoreProfile(storeId, {fieldKey: value});
    ref.invalidate(myStoresProvider);
  }

  Future<void> updateStoreAddress(
    String storeId, {
    required String zipCode,
    required String prefecture,
    required String city,
    required String address,
    required String building,
  }) async {
    final service = ref.read(profileServiceProvider);
    await service.updateStoreProfile(storeId, {
      'zip_code': zipCode,
      'prefecture': prefecture,
      'city': city,
      'address': address,
      'building': building,
    });
    ref.invalidate(myStoresProvider);
  }

  Future<void> uploadStoreImage(String storeId) async {
    if (_isPickingImage) return; // 連打による二重起動を無視
    _isPickingImage = true;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
        requestFullMetadata: false,
      );
      if (pickedFile == null) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw const ApiException('User not logged in.');
      final idToken = await currentUser.getIdToken(true);
      if (idToken == null) {
        throw const ApiException('Could not get auth token.');
      }

      final service = ref.read(profileServiceProvider);
      await service.uploadStoreImage(File(pickedFile.path), storeId, idToken);
      ref.invalidate(myStoresProvider);
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> uploadStoreLicense(String storeId, File imageFile) async {
    final service = ref.read(profileServiceProvider);
    await service.uploadLicenseImage(storeId, imageFile);
    ref.invalidate(storeLicenseProvider(storeId: storeId));
  }

  Future<void> updateStoreSettings(StoreSettings newSettings) async {
    final service = ref.read(storeSettingsServiceProvider);
    await service.updateStoreSettings(newSettings);
    ref.invalidate(storeSettingsProvider(storeId: newSettings.storeId));
  }
}
