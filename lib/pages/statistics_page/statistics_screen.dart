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
    // 期間/日付/指標の選択はページローカルなephemeral UI状態のためHooksで管理
    final selectedPeriod = useState('auto'); // 'auto', 'weekly', 'monthly', 'yearly'
    final selectedMetric = useState('visitor'); // 'visitor', 'no_show', 'cancelled'
    final currentDate = useState(DateTime.now());

    // 既存 StatisticsViewModel の formattedDate/isCurrentPeriod と同一ロジック
    String formattedDate() {
      if (selectedPeriod.value == 'weekly') {
        final start = currentDate.value.subtract(const Duration(days: 6));
        return "${start.month}月${start.day}日 - ${currentDate.value.month}月${currentDate.value.day}日";
      } else if (selectedPeriod.value == 'monthly') {
        return "${currentDate.value.year}年 ${currentDate.value.month}月";
      } else if (selectedPeriod.value == 'yearly') {
        return "${currentDate.value.year}年";
      }
      return "${currentDate.value.year}年 ${currentDate.value.month}月 ${currentDate.value.day}日";
    }

    bool isCurrentPeriod() {
      final now = DateTime.now();
      if (selectedPeriod.value == 'weekly') {
        final diff = now.difference(currentDate.value).inDays;
        return diff < 1 && diff >= 0 && now.day == currentDate.value.day;
      } else if (selectedPeriod.value == 'monthly') {
        return now.year == currentDate.value.year &&
            now.month == currentDate.value.month;
      } else if (selectedPeriod.value == 'yearly') {
        return now.year == currentDate.value.year;
      }
      return now.difference(currentDate.value).inDays == 0 &&
          now.day == currentDate.value.day;
    }

    void setPeriod(String period) {
      if (selectedPeriod.value == period) return;
      selectedPeriod.value = period;
      // 期間タイプ変更時は今日にリセット
      currentDate.value = DateTime.now();
    }

    void setMetric(String metric) {
      if (selectedMetric.value == metric) return;
      selectedMetric.value = metric;

      // 'no_show'/'cancelled' に切り替える際、現在の期間が'auto'（今日）なら'weekly'に切り替える
      // 'auto'には時間別のNo-Show/Cancelデータが存在しないため
      if ((metric == 'no_show' || metric == 'cancelled') &&
          selectedPeriod.value == 'auto') {
        selectedPeriod.value = 'weekly';
        currentDate.value = DateTime.now();
      }
    }

    void previousPeriod() {
      if (selectedPeriod.value == 'weekly') {
        currentDate.value = currentDate.value.subtract(const Duration(days: 7));
      } else if (selectedPeriod.value == 'monthly') {
        currentDate.value = DateTime(
            currentDate.value.year, currentDate.value.month - 1, 1);
      } else if (selectedPeriod.value == 'yearly') {
        currentDate.value = DateTime(currentDate.value.year - 1, 1, 1);
      } else {
        currentDate.value = currentDate.value.subtract(const Duration(days: 1));
      }
    }

    void nextPeriod() {
      if (isCurrentPeriod()) return; // 未来への移動を制限

      DateTime next;
      if (selectedPeriod.value == 'weekly') {
        next = currentDate.value.add(const Duration(days: 7));
      } else if (selectedPeriod.value == 'monthly') {
        next = DateTime(currentDate.value.year, currentDate.value.month + 1, 1);
      } else if (selectedPeriod.value == 'yearly') {
        next = DateTime(currentDate.value.year + 1, 1, 1);
      } else {
        next = currentDate.value.add(const Duration(days: 1));
      }

      if (next.isAfter(DateTime.now())) {
        next = DateTime.now();
      }
      currentDate.value = next;
    }

    final provider = statisticsDataProvider(
      storeId: storeId,
      period: selectedPeriod.value,
      date: currentDate.value,
    );
    final statsAsync = ref.watch(provider);

    Future<void> refresh() => ref.refresh(provider.future);

    final data = statsAsync.valueOrNull;

    final visitorStats = data?['visitor_stats'];
    final hourlyCongestion =
        (data?['hourly_congestion'] as List<dynamic>?) ?? [];
    final avgWaitTime = (data?['average_wait_time'] as String?) ?? '0分';
    final noShowRate = ((data?['no_show_rate'] as num?) ?? 0).toDouble();
    final totalCancelled = (data?['total_cancelled'] as num?)?.toInt() ?? 0;
    final totalNoShow = (data?['total_no_show'] as num?)?.toInt() ?? 0;

    // Determine Highlight Data based on Selection
    String highlightTitle = '来店数';
    int highlightValue = visitorStats?['today'] ?? 0;
    Color highlightColor = const Color(0xFF212529);
    IconData? highlightIcon;

    if (selectedMetric.value == 'cancelled') {
      highlightTitle = 'キャンセル数';
      highlightValue = totalCancelled;
      highlightColor = const Color(0xFFFA5252);
      highlightIcon = Icons.cancel_outlined;
    } else if (selectedMetric.value == 'no_show') {
      highlightTitle = 'No-Show数';
      highlightValue = totalNoShow;
      highlightColor = const Color(0xFFFF6B6B);
      highlightIcon = Icons.person_off_outlined;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Softer background
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
        visitorStats,
        hourlyCongestion,
        avgWaitTime,
        noShowRate,
        highlightTitle,
        highlightValue,
        highlightColor,
        highlightIcon,
        selectedPeriod.value,
        selectedMetric.value,
        formattedDate(),
        isCurrentPeriod(),
        setPeriod,
        setMetric,
        previousPeriod,
        nextPeriod,
        refresh,
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      AsyncValue<Map<String, dynamic>> statsAsync,
      Map<String, dynamic>? data,
      dynamic visitorStats,
      List<dynamic> hourlyCongestion,
      String avgWaitTime,
      double noShowRate,
      String highlightTitle,
      int highlightValue,
      Color highlightColor,
      IconData? highlightIcon,
      String selectedPeriod,
      String selectedMetric,
      String formattedDate,
      bool isCurrentPeriod,
      void Function(String) setPeriod,
      void Function(String) setMetric,
      VoidCallback previousPeriod,
      VoidCallback nextPeriod,
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
                  selectedPeriod == 'weekly'
                      ? '週間ハイライト'
                      : selectedPeriod == 'monthly'
                          ? '月間ハイライト'
                          : selectedPeriod == 'yearly'
                              ? '年間ハイライト'
                              : '本日のハイライト',
                ),
                const SizedBox(height: 12),
                _buildVisitorCard(visitorStats,
                    overrideTitle: highlightTitle,
                    overrideValue: highlightValue,
                    overrideColor: highlightColor,
                    overrideIcon: highlightIcon),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        '平均待ち時間',
                        avgWaitTime,
                        Icons.timer_outlined,
                        const Color(0xFF4C6EF5), // Indigo
                        const Color(0xFFE7F5FF),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        'No-Show率',
                        '${noShowRate.toStringAsFixed(1)}%',
                        Icons.person_off_outlined,
                        const Color(0xFFFA5252), // Red
                        const Color(0xFFFFF5F5),
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
                    color: const Color(0xFFEFF0F3),
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
                                        ? const Color(0xFF212529)
                                        : const Color(0xFF868E96),
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
                                        ? const Color(0xFF212529)
                                        : const Color(0xFF868E96),
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
                                        ? const Color(0xFF212529)
                                        : const Color(0xFF868E96),
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

                // Period Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodButton(
                          selectedPeriod, setPeriod, 'auto', '今日',
                          isDisabled: selectedMetric == 'no_show' ||
                              selectedMetric == 'cancelled'),
                      const SizedBox(width: 8),
                      _buildPeriodButton(
                          selectedPeriod, setPeriod, 'weekly', '週間'),
                      const SizedBox(width: 8),
                      _buildPeriodButton(
                          selectedPeriod, setPeriod, 'monthly', '月間'),
                      const SizedBox(width: 8),
                      _buildPeriodButton(
                          selectedPeriod, setPeriod, 'yearly', '年間'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Date Navigator (Visible only when not 'auto')
                if (selectedPeriod != 'auto') ...[
                  Container(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: previousPeriod,
                          icon:
                              const Icon(Icons.chevron_left_rounded, size: 32),
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          // 未来への移動は isCurrentPeriod で制御
                          onPressed: isCurrentPeriod ? null : nextPeriod,
                          icon:
                              const Icon(Icons.chevron_right_rounded, size: 32),
                          color: isCurrentPeriod
                              ? Colors.black12
                              : Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),

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
                  if (selectedPeriod == 'auto')
                    DynamicChartCard(
                        chartData: hourlyCongestion.map((e) {
                      return {
                        'label': e['hour'].toString(),
                        'value': e['count'],
                        'prev_value': e['prev_count'] ?? 0,
                      };
                    }).toList())
                  else
                    DynamicChartCard(
                        chartData: data['chart_data'] as List<dynamic>?)
                else if (selectedMetric == 'cancelled')
                  DynamicChartCard(
                      chartData: data['cancelled_chart_data'] as List<dynamic>?)
                else
                  DynamicChartCard(
                      chartData: data['no_show_chart_data'] as List<dynamic>?),
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
        color: Color(0xFF343A40),
      ),
    );
  }

  Widget _buildVisitorCard(Map<String, dynamic> stats,
      {String? overrideTitle,
      int? overrideValue,
      Color? overrideColor,
      IconData? overrideIcon}) {
    final value = overrideValue ?? (stats['today'] as int);
    final title = overrideTitle ?? '総来店者数';

    final wowRate = (stats['wow_growth_rate'] as num).toDouble();
    final isPositive = wowRate >= 0;

    // Only show growth rate (comparison) if showing Visitor Stats (default)
    final showGrowth = overrideValue == null;

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
                  const Color(0xFF2E2E2E), // Dark Gray
                  const Color(0xFF1A1A1A), // Black
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
                              ? const Color(0xFF1B4D3E) // Dark Green bg
                              : const Color(0xFF4A1B1B), // Dark Red bg
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPositive
                                ? const Color(0xFF4CD964)
                                : const Color(0xFFFF3B30),
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
                                  ? const Color(0xFF4CD964)
                                  : const Color(0xFFFF3B30),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${wowRate.abs().toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: isPositive
                                    ? const Color(0xFF4CD964)
                                    : const Color(0xFFFF3B30),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Optional: Add icon for Cancel/No-Show if desired, or nothing.
                      // Let's add an icon to make it look balanced.
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
                        '人', // Could make this dynamic '件' if needed, but '人' is safer default
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
                if (showGrowth)
                  const Text(
                    '先週の同曜日と比較',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  )
                else
                  Text(
                    '選択期間の合計',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData outlineIconForMetric(String metric) {
    switch (metric) {
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'no_show':
        return Icons.person_off_outlined;
      default:
        return Icons.people_outline;
    }
  }

  Widget _buildPeriodButton(String selectedPeriod,
      void Function(String) setPeriod, String period, String label,
      {bool isDisabled = false}) {
    final isSelected = selectedPeriod == period;
    return InkWell(
      onTap: isDisabled ? null : () => setPeriod(period),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.withOpacity(0.1)
              : (isSelected ? const Color(0xFF2E2E2E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDisabled
                ? Colors.black26
                : (isSelected ? Colors.white : Colors.black54),
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
              color: Color(0xFF868E96),
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
              color: Color(0xFF212529),
            ),
          ),
        ],
      ),
    );
  }
}
