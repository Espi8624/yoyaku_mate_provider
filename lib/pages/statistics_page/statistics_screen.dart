import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/statistics_page/statistics_providers.dart';
import 'widgets/dynamic_chart_card.dart';

class StatisticsScreen extends StatelessWidget {
  final String storeId;

  const StatisticsScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return _StatisticsView(storeId: storeId);
  }
}

class _StatisticsView extends HookConsumerWidget {
  final String storeId;

  const _StatisticsView({required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 期間/指標の選択はページローカルなephemeral UI状態のためHooksで管理。
    // 過去の期間へのナビゲーションは提供せず、常に「今日」「今週」固定。
    final selectedPeriod = useState('auto'); // 'auto'(今日), 'weekly'(今週=日〜土)
    final selectedMetric = useState('visitor'); // 'visitor', 'no_show', 'cancelled'

    void setPeriod(String period) {
      selectedPeriod.value = period;
    }

    void setMetric(String metric) {
      selectedMetric.value = metric;
    }

    final provider = statisticsDataProvider(
      storeId: storeId,
      period: selectedPeriod.value,
    );
    final statsAsync = ref.watch(provider);

    Future<void> refresh() => ref.refresh(provider.future);

    final data = statsAsync.valueOrNull;

    final visitorTotal = (data?['visitor_total'] as num?)?.toInt() ?? 0;
    final visitorGrowthRate =
        ((data?['visitor_growth_rate'] as num?) ?? 0).toDouble();
    final avgWaitTime = (data?['average_wait_time'] as String?) ?? '--分';
    final noShowRate = ((data?['no_show_rate'] as num?) ?? 0).toDouble();
    final totalCancelled = (data?['cancelled_total'] as num?)?.toInt() ?? 0;
    final totalNoShow = (data?['no_show_total'] as num?)?.toInt() ?? 0;

    // 選択中の指標に応じたハイライト表示内容を決定
    String highlightTitle = '来店数';
    int highlightValue = visitorTotal;
    Color highlightColor = AppColors.statChartDark;
    IconData? highlightIcon;

    if (selectedMetric.value == 'cancelled') {
      highlightTitle = 'キャンセル数';
      highlightValue = totalCancelled;
      highlightColor = AppColors.statDangerRed;
      highlightIcon = Icons.cancel_outlined;
    } else if (selectedMetric.value == 'no_show') {
      highlightTitle = 'No-Show数';
      highlightValue = totalNoShow;
      highlightColor = AppColors.statAlertRed;
      highlightIcon = Icons.person_off_outlined;
    }

    return Scaffold(
      backgroundColor: AppColors.background, // Softer background
      appBar: AppBar(
        title: const Text(
          '統計',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: _buildBody(
        context,
        statsAsync,
        data,
        visitorTotal,
        visitorGrowthRate,
        avgWaitTime,
        noShowRate,
        highlightTitle,
        highlightValue,
        highlightColor,
        highlightIcon,
        selectedPeriod.value,
        selectedMetric.value,
        setPeriod,
        setMetric,
        refresh,
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      AsyncValue<Map<String, dynamic>> statsAsync,
      Map<String, dynamic>? data,
      int visitorTotal,
      double visitorGrowthRate,
      String avgWaitTime,
      double noShowRate,
      String highlightTitle,
      int highlightValue,
      Color highlightColor,
      IconData? highlightIcon,
      String selectedPeriod,
      String selectedMetric,
      void Function(String) setPeriod,
      void Function(String) setMetric,
      Future<void> Function() refresh) {
    final isLoading = statsAsync.isLoading && data == null;

    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }

    if (statsAsync.hasError && data == null) {
      if (statsAsync.error.toString().contains('403')) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.pendingBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock_outlined,
                    size: 48,
                    color: AppColors.pending,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'アクセス権限がありません',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '統計情報を閲覧するには、\n管理者による承認が必要です。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再読み込み'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${statsAsync.error}'),
            ElevatedButton(
              onPressed: refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (data == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
        onRefresh: refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Builder(builder: (context) {
            // --- 1. Define Highlight Section ---
            final highlightSection = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle(
                    selectedPeriod == 'weekly' ? '今週のハイライト' : '本日のハイライト'),
                const SizedBox(height: 12),
                _buildVisitorCard(
                  overrideTitle: highlightTitle,
                  overrideValue: highlightValue,
                  overrideColor: highlightColor,
                  overrideIcon: highlightIcon,
                  visitorTotal: visitorTotal,
                  growthRate: visitorGrowthRate,
                  comparisonLabel: '先週と比較',
                  // 成長率バッジは「来店数」ハイライト かつ 今週ビューの時のみ表示。
                  // 「今日」は前日比だと曜日差(週末/平日など)のノイズが大きく、
                  // 誤解を招く数値になりやすいため意図的に非表示にしている。
                  showGrowth:
                      selectedMetric == 'visitor' && selectedPeriod == 'weekly',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        '平均待ち時間',
                        avgWaitTime,
                        Icons.timer_outlined,
                        AppColors.statIndigo, // Indigo
                        AppColors.statIndigoBg,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        'No-Show率',
                        '${noShowRate.toStringAsFixed(1)}%',
                        Icons.person_off_outlined,
                        AppColors.statDangerRed, // Red
                        AppColors.statDangerRedBg,
                      ),
                    ),
                  ],
                ),
              ],
            );

            // --- 2. Define Chart Section ---
            final chartSection = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('統計トレンド'),
                const SizedBox(height: 12),
                // Metric Selector Tabs (High Level)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.statTabTrackBg,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Stack(
                    children: [
                      // Sliding Background Indicator
                      AnimatedAlign(
                        alignment: selectedMetric == 'visitor'
                            ? Alignment.centerLeft
                            : (selectedMetric == 'cancelled'
                                ? Alignment.center
                                : Alignment.centerRight),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: FractionallySizedBox(
                          widthFactor: 0.33,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  offset: const Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Tab Labels
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setMetric('visitor'),
                              behavior: HitTestBehavior.translucent,
                              child: Center(
                                child: Text(
                                  '来店数',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selectedMetric == 'visitor'
                                        ? AppColors.statChartDark
                                        : AppColors.statChartMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setMetric('cancelled'),
                              behavior: HitTestBehavior.translucent,
                              child: Center(
                                child: Text(
                                  'キャンセル',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selectedMetric == 'cancelled'
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: selectedMetric == 'cancelled'
                                        ? AppColors.statChartDark
                                        : AppColors.statChartMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setMetric('no_show'),
                              behavior: HitTestBehavior.translucent,
                              child: Center(
                                child: Text(
                                  'No-Show',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selectedMetric == 'no_show'
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: selectedMetric == 'no_show'
                                        ? AppColors.statChartDark
                                        : AppColors.statChartMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Period Selector（今日 / 今週の2つのみ。過去への移動はなし）
                Row(
                  children: [
                    _buildPeriodButton(selectedPeriod, setPeriod, 'auto', '今日'),
                    const SizedBox(width: 8),
                    _buildPeriodButton(
                        selectedPeriod, setPeriod, 'weekly', '今週'),
                  ],
                ),
                const SizedBox(height: 12),

                // Chart Display
                if (statsAsync.isLoading)
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          offset: const Offset(0, 4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accentPrimary)),
                  )
                else if (selectedMetric == 'visitor')
                  DynamicChartCard(
                      chartData: data['visitor_chart'] as List<dynamic>?)
                else if (selectedMetric == 'cancelled')
                  DynamicChartCard(
                      chartData: data['cancelled_chart'] as List<dynamic>?)
                else
                  DynamicChartCard(
                      chartData: data['no_show_chart'] as List<dynamic>?),
              ],
            );

            // --- 3. Return Responsive Layout ---
            return OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.portrait) {
                  return Column(
                    children: [
                      highlightSection,
                      const SizedBox(height: 32),
                      chartSection,
                      const SizedBox(height: 40),
                    ],
                  );
                } else {
                  // Landscape Layout (Side-by-Side)
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: highlightSection,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 6,
                        child: chartSection,
                      ),
                    ],
                  );
                }
              },
            );
          }),
        ));
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.statSectionTitle,
      ),
    );
  }

  Widget _buildVisitorCard({
    required int visitorTotal,
    required double growthRate,
    required String comparisonLabel,
    required bool showGrowth,
    String? overrideTitle,
    int? overrideValue,
    Color? overrideColor,
    IconData? overrideIcon,
  }) {
    final value = overrideValue ?? visitorTotal;
    final title = overrideTitle ?? '総来店者数';
    final isPositive = growthRate >= 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: overrideColor != null
              ? [
                  overrideColor,
                  overrideColor.withOpacity(0.8),
                ]
              : [
                  AppColors.statDarkCardGradientStart, // Dark Gray
                  AppColors.statDarkCardGradientEnd, // Black
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (overrideColor ?? Colors.black).withOpacity(0.15),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative circle
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (showGrowth)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? AppColors.statPositiveBg // Dark Green bg
                              : AppColors.statNegativeBg, // Dark Red bg
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPositive
                                ? AppColors.statPositiveGreen
                                : AppColors.statNegativeRed,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 14,
                              color: isPositive
                                  ? AppColors.statPositiveGreen
                                  : AppColors.statNegativeRed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${growthRate.abs().toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: isPositive
                                    ? AppColors.statPositiveGreen
                                    : AppColors.statNegativeRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          overrideIcon ?? Icons.people_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '人',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  showGrowth ? comparisonLabel : '選択期間の合計',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String selectedPeriod,
      void Function(String) setPeriod, String period, String label) {
    final isSelected = selectedPeriod == period;
    return InkWell(
      onTap: () => setPeriod(period),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.statDarkCardGradientStart : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon,
      Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.statChartMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.statChartDark,
            ),
          ),
        ],
      ),
    );
  }
}
