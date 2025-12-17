import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../services/api_exception.dart';
import '../../constants/staff_status.dart';

class StaffManagementViewModel extends ChangeNotifier {
  final ProviderProfileService _profileService;

  StaffManagementViewModel({required ProviderProfileService profileService})
      : _profileService = profileService;

  // --- State ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<dynamic> _staffList = [];
  List<dynamic> get staffList => _staffList;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

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
