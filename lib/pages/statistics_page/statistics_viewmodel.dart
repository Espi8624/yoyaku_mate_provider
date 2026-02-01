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

  String _selectedPeriod = 'auto'; // 'auto', 'weekly', 'monthly', 'yearly'
  String get selectedPeriod => _selectedPeriod;

  String _selectedMetric = 'visitor'; // 'visitor', 'no_show', 'cancelled'
  String get selectedMetric => _selectedMetric;

  DateTime _currentDate = DateTime.now();
  DateTime get currentDate => _currentDate;

  String get formattedDate {
    if (_selectedPeriod == 'weekly') {
      // 週間: "1月28日 - 2月3日" のように表示したいが、簡単のため開始日を表示 or "2024年 1月"
      // 実装プランでは "2024年 1月" とあったが、週間なら週の範囲がいいかも。
      // Unity check: "Start Date" is 6 days ago.
      // Let's just show "2024年 1月" covering the reference date for now, or specific date.
      // If we navigation by 7 days, "1/20 - 1/26" is better.
      final start = _currentDate.subtract(const Duration(days: 6));
      return "${start.month}月${start.day}日 - ${_currentDate.month}月${_currentDate.day}日";
    } else if (_selectedPeriod == 'monthly') {
      return "${_currentDate.year}年 ${_currentDate.month}月";
    } else if (_selectedPeriod == 'yearly') {
      return "${_currentDate.year}年";
    }
    return "${_currentDate.year}年 ${_currentDate.month}月 ${_currentDate.day}日";
  }

  bool get isCurrentPeriod {
    final now = DateTime.now();
    if (_selectedPeriod == 'weekly') {
      // 差が7日以内かつ未来でない
      // 厳密には "今日" が含まれていれば OK
      final diff = now.difference(_currentDate).inDays;
      return diff < 1 && diff >= 0 && now.day == _currentDate.day;
    } else if (_selectedPeriod == 'monthly') {
      return now.year == _currentDate.year && now.month == _currentDate.month;
    } else if (_selectedPeriod == 'yearly') {
      return now.year == _currentDate.year;
    }
    // auto / others
    return now.difference(_currentDate).inDays == 0 &&
        now.day == _currentDate.day;
  }

  StatisticsViewModel({
    required StatisticsService service,
    required this.storeId,
  }) : _service = service {
    loadStatistics();
  }

  void setPeriod(String period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    // Reset to today when changing period type
    _currentDate = DateTime.now();
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
      _currentDate = DateTime.now(); // Reset date if auto switched
    }

    notifyListeners();
    // 期間が変更された場合は統計情報のロードを開始する、あるいは既にデータがある場合は通知のみ行う
    if (_selectedPeriod == 'weekly') {
      // 期間が自動的に切り替わった場合は、データをロードする必要がある
      loadStatistics();
    }
  }

  void previousPeriod() {
    if (_selectedPeriod == 'weekly') {
      _currentDate = _currentDate.subtract(const Duration(days: 7));
    } else if (_selectedPeriod == 'monthly') {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
      // 月末補正 (例: 3/31 -> 2/28) は DateTime コンストラクタが自動でやってくれない場合がある
      // しかし backend は year/month/1 を基準にするか、単にその月が含まれていればOK。
      // Backend handles "beginning of month", so simply changing month is enough.
      // Just ensure we don't overflow if day is 31 and prev month has 30.
      // Let's set day to 1 to be safe for monthly navigation context,
      // BUT if we want to come back to "Today" later, we lose the day.
      // Backend logic uses "Now (Reference Date)" to determine "Today".
      // If we pass 2024-02-01, backend treats "today" as 2024-02-01.
      // For monthly stats, start date is 1st.
      // So setting day to 1 is fine.
    } else if (_selectedPeriod == 'yearly') {
      _currentDate = DateTime(_currentDate.year - 1, 1, 1);
    } else {
      // auto / daily
      _currentDate = _currentDate.subtract(const Duration(days: 1));
    }
    loadStatistics();
  }

  void nextPeriod() {
    if (isCurrentPeriod) return; // Future navigation blocking (optional)

    if (_selectedPeriod == 'weekly') {
      _currentDate = _currentDate.add(const Duration(days: 7));
    } else if (_selectedPeriod == 'monthly') {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
    } else if (_selectedPeriod == 'yearly') {
      _currentDate = DateTime(_currentDate.year + 1, 1, 1);
    } else {
      _currentDate = _currentDate.add(const Duration(days: 1));
    }

    // Future check clamping
    if (_currentDate.isAfter(DateTime.now())) {
      _currentDate = DateTime.now();
    }

    loadStatistics();
  }

  Future<void> loadStatistics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.fetchStatistics(storeId,
          period: _selectedPeriod, date: _currentDate);
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
