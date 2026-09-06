// 統計画面の状態管理 (Riverpod)
//
// Provider(MVVM)からの移行。他ページから参照されないページローカル状態。
//
// 機能を「今日(auto)」「今週=日〜土(weekly)」の2ビューに絞ったため、
// (storeId, period) の組み合わせに対する統計データ取得のみを扱う。
// 過去の期間へのナビゲーションは提供しない（常に直近の今日/今週固定）。
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
}) async {
  final service = ref.watch(statisticsServiceProvider);
  return service.fetchStatistics(storeId, period: period);
}
