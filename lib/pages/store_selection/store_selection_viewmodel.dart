import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/models/store_profile.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen_viewmodel.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/services/profile_service.dart';

class StoreSelectionViewModel extends ChangeNotifier {
  final ProviderProfileService _profileService;
  final ProfileScreenViewModel _profileVM;

  StoreSelectionViewModel({
    required ProviderProfileService profileService,
    required ProfileScreenViewModel profileVM,
  })  : _profileService = profileService,
        _profileVM = profileVM;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Store listは主にProfileScreenViewModelで管理する
  List<StoreProfile> get stores => _profileVM.myStores;

  Future<void> refreshStores() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileVM.loadProfiles(forceRefresh: true);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> selectStore(String storeId) async {
    return await _profileVM.selectStore(storeId);
  }

  Future<bool> joinStore(String storeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileService.joinStore(storeId);
      _successMessage = "参加リクエストを送信しました。承認をお待ちください。";
      await refreshStores();
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
}
