// 統計画面の状態管理 (Riverpod)
//
// Provider(MVVM)からの移行。他ページから参照されないページローカル状態。
//
// 期間(period)/日付(date)/指標(metric)の選択は純粋なephemeral UI状態のため
// 画面側でflutter_hooksのuseStateとして管理し、ここでは
// (storeId, period, date)の組み合わせに対する統計データ取得のみを扱う。
// metricは表示フィルタに過ぎずAPIリクエストに影響しないためfamilyパラメータに含めない。
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yoyaku_mate_provider/services/statistics_service.dart';

part 'statistics_providers.g.dart';

@riverpod
StatisticsService statisticsService(Ref ref) =>
    StatisticsService(baseUrl: dotenv.env['API_URL'] ?? '');

@riverpod
Future<Map<String, dynamic>> statisticsData(
  Ref ref, {
  required String storeId,
  required String period,
  required DateTime date,
}) async {
  final service = ref.watch(statisticsServiceProvider);

  // 既存の loadStatistics() の startDate/endDate 算出ロジックをそのまま移植
  late final DateTime startDate;
  late final DateTime endDate;
  if (period == 'weekly') {
    endDate = date;
    startDate = date.subtract(const Duration(days: 6));
  } else if (period == 'monthly') {
    startDate = DateTime(date.year, date.month, 1);
    endDate = DateTime(date.year, date.month + 1, 0);
  } else if (period == 'yearly') {
    startDate = DateTime(date.year, 1, 1);
    endDate = DateTime(date.year, 12, 31);
  } else {
    // Auto / Daily
    startDate = date;
    endDate = date;
  }

  return service.fetchStatistics(
    storeId,
    period: period,
    date: date,
    startDate: startDate,
    endDate: endDate,
  );
}
