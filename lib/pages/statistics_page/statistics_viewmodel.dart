import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/services/statistics_service.dart';

class StatisticsViewModel extends ChangeNotifier {
  final StatisticsService _service;
  final String storeId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? _statisticsData;
  Map<String, dynamic>? get statisticsData => _statisticsData;

  String _selectedPeriod =
      'auto'; // 'auto'（今日）, 'weekly'（週間）, 'monthly'（月間）, 'yearly'（年間）
  String get selectedPeriod => _selectedPeriod;

  String _selectedMetric = 'visitor'; // 'visitor'（来店数）, 'no_show'（No-Show数）
  String get selectedMetric => _selectedMetric;

  StatisticsViewModel({
    required StatisticsService service,
    required this.storeId,
  }) : _service = service {
    loadStatistics();
  }

  void setPeriod(String period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    loadStatistics();
  }

  void setMetric(String metric) {
    if (_selectedMetric == metric) return;
    _selectedMetric = metric;

    // 'no_show' または 'cancelled' に切り替える際、現在の期間が'auto'（今日）の場合は'weekly'（週間）に切り替える
    // 'auto'（今日）には時間別のNo-Show/Cancelデータが存在しないため。
    if ((_selectedMetric == 'no_show' || _selectedMetric == 'cancelled') &&
        _selectedPeriod == 'auto') {
      _selectedPeriod = 'weekly';
    }

    notifyListeners();
    // 期間が変更された場合は統計情報のロードを開始する、あるいは既にデータがある場合は通知のみ行う
    // （ロジックが変わる場合は再ロードが必要かもしれないが、ここでは正しいデータが表示されることを保証するだけでよい。
    // no_showのチャートデータは既に取得済みなので、単にビューを切り替えるだけならloadStatistics()は不要かもしれないが、
    // 上記の期間変更ロジックがあるためロードが必要となる。）
    if (_selectedPeriod == 'weekly') {
      // 期間が自動的に切り替わった場合は、データをロードする必要がある
      loadStatistics();
    }
  }

  Future<void> loadStatistics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data =
          await _service.fetchStatistics(storeId, period: _selectedPeriod);
      _statisticsData = data;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadStatistics();
  }
}
