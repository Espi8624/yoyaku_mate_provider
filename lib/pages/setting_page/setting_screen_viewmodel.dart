import 'package:flutter/material.dart';
import '../../models/store_settings.dart';
import '../../services/store_settings_service.dart';

class SettingScreenViewModel extends ChangeNotifier {
  final String storeId;
  final _service = StoreSettingsService(baseUrl: 'http://localhost:8080');

  SettingScreenViewModel({required this.storeId}) {
    fetchSettings();
  }

  StoreSettings? _storeSettings;
  StoreSettings? get storeSettings => _storeSettings;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _storeSettings = await _service.fetchStoreSettings(storeId);
    } catch (e) {
      _errorMessage = '設定情報の読み込みに失敗しました: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings(StoreSettings updatedSettings) async {
    _storeSettings = updatedSettings;
    notifyListeners(); // UI 即反映

    try {
      await _service.updateStoreSettings(updatedSettings);
    } catch (e) {
      _errorMessage = '設定の保存に失敗しました: $e';
      await fetchSettings(); // 保存失敗時、ロールバック
    }
  }
}
