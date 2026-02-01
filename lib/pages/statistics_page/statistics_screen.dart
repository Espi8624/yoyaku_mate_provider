import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/statistics_page/statistics_viewmodel.dart';
import 'package:yoyaku_mate_provider/services/statistics_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StatisticsScreen extends StatelessWidget {
  final String storeId;

  const StatisticsScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatisticsViewModel(
        service: StatisticsService(baseUrl: dotenv.env['API_URL'] ?? ''),
        storeId: storeId,
      ),
      child: const _StatisticsView(),
    );
  }
}

class _StatisticsView extends StatelessWidget {
  const _StatisticsView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StatisticsViewModel>();
    final data = viewModel.statisticsData;

    // Initial Loading (No data yet)
    if (viewModel.isLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null && data == null) {
      if (viewModel.errorMessage!.contains('403')) {
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
                  onPressed: viewModel.refresh,
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
            Text('Error: ${viewModel.errorMessage}'),
            ElevatedButton(
              onPressed: viewModel.refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (data == null) {
      return const Center(child: Text('No data available'));
    }

    final visitorStats = data['visitor_stats'];
    final hourlyCongestion = data['hourly_congestion'] as List<dynamic>;
    final avgWaitTime = data['average_wait_time'] as String;
    final noShowRate = (data['no_show_rate'] as num).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Softer background
      appBar: AppBar(
        title: const Text(
          '統計',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('本日のハイライト'),
              const SizedBox(height: 12),
              _buildVisitorCard(visitorStats),
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
              const SizedBox(height: 32),

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
                      alignment: viewModel.selectedMetric == 'visitor'
                          ? Alignment.centerLeft
                          : (viewModel.selectedMetric == 'cancelled'
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
                            onTap: () => viewModel.setMetric('visitor'),
                            behavior: HitTestBehavior.translucent,
                            child: Center(
                              child: Text(
                                '来店数',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: viewModel.selectedMetric == 'visitor'
                                      ? const Color(0xFF212529)
                                      : const Color(0xFF868E96),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => viewModel.setMetric('cancelled'),
                            behavior: HitTestBehavior.translucent,
                            child: Center(
                              child: Text(
                                'キャンセル',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      viewModel.selectedMetric == 'cancelled'
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                  color: viewModel.selectedMetric == 'cancelled'
                                      ? const Color(0xFF212529)
                                      : const Color(0xFF868E96),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => viewModel.setMetric('no_show'),
                            behavior: HitTestBehavior.translucent,
                            child: Center(
                              child: Text(
                                'No-Show',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      viewModel.selectedMetric == 'no_show'
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                  color: viewModel.selectedMetric == 'no_show'
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
                    _buildPeriodButton(viewModel, 'auto', '今日',
                        isDisabled: viewModel.selectedMetric == 'no_show' ||
                            viewModel.selectedMetric == 'cancelled'),
                    const SizedBox(width: 8),
                    _buildPeriodButton(viewModel, 'weekly', '週間'),
                    const SizedBox(width: 8),
                    _buildPeriodButton(viewModel, 'monthly', '月間'),
                    const SizedBox(width: 8),
                    _buildPeriodButton(viewModel, 'yearly', '年間'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Date Navigator (Visible only when not 'auto')
              if (viewModel.selectedPeriod != 'auto') ...[
                Container(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: viewModel.previousPeriod,
                        icon: const Icon(Icons.chevron_left_rounded, size: 32),
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        viewModel.formattedDate,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        // 未来への移動は isCurrentPeriod で制御
                        onPressed: viewModel.isCurrentPeriod
                            ? null
                            : viewModel.nextPeriod,
                        icon: const Icon(Icons.chevron_right_rounded, size: 32),
                        color: viewModel.isCurrentPeriod
                            ? Colors.black12
                            : Colors.black54,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 4),

              // Chart Display
              if (viewModel.isLoading)
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
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (viewModel.selectedMetric == 'visitor')
                if (viewModel.selectedPeriod == 'auto')
                  _buildDynamicChartCard(hourlyCongestion.map((e) {
                    return {
                      'label': e['hour'].toString(),
                      'value': e['count'],
                      'prev_value': e['prev_count'] ?? 0,
                    };
                  }).toList())
                else
                  _buildDynamicChartCard(data['chart_data'] as List<dynamic>?)
              else if (viewModel.selectedMetric == 'cancelled')
                _buildDynamicChartCard(
                    data['cancelled_chart_data'] as List<dynamic>?)
              else
                _buildDynamicChartCard(
                    data['no_show_chart_data'] as List<dynamic>?),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildVisitorCard(Map<String, dynamic> stats) {
    final today = stats['today'] as int;
    final wowRate = (stats['wow_growth_rate'] as num).toDouble();
    final isPositive = wowRate >= 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E2E2E), // Dark Gray
            Color(0xFF1A1A1A), // Black
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
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
                    const Text(
                      '総来店者数',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$today',
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
                const Text(
                  '先週の同曜日と比較',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPeriodButton(
      StatisticsViewModel viewModel, String period, String label,
      {bool isDisabled = false}) {
    final isSelected = viewModel.selectedPeriod == period;
    return InkWell(
      onTap: isDisabled ? null : () => viewModel.setPeriod(period),
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

  Widget _buildDynamicChartCard(List<dynamic>? chartData) {
    if (chartData == null || chartData.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('データがありません'),
      );
    }

    // Determine max Y including both current and previous values
    double maxY = 10.0;
    if (chartData.isNotEmpty) {
      final maxVal = chartData
          .map((e) => (e['value'] as num).toDouble())
          .reduce((curr, next) => curr > next ? curr : next);
      final maxPrev = chartData
          .map((e) => (e['prev_value'] as num?)?.toDouble() ?? 0.0)
          .reduce((curr, next) => curr > next ? curr : next);
      final absoluteMax = maxVal > maxPrev ? maxVal : maxPrev;
      // Ensure minimum height of 10 and add 20% padding
      maxY = (absoluteMax < 10.0 ? 10.0 : absoluteMax) * 1.2;
    }

    return Container(
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
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        child: Column(
          children: [
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildLegendItem(
                  color: const Color(0xFF212529),
                  label: '今回',
                  isCircle: false,
                ),
                const SizedBox(width: 16),
                _buildLegendItem(
                  color: const Color(0xFFFF6B6B),
                  label: '前回',
                  isCircle: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                children: [
                  // Layer 1: Bar Chart (Current Period - Visuals Only)
                  BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceBetween,
                      maxY: maxY,
                      minY: 0,
                      barTouchData:
                          BarTouchData(enabled: false), // Handled by LineChart
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < chartData.length) {
                                if (chartData.length > 10 && index % 2 != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    chartData[index]['label'].toString(),
                                    style: const TextStyle(
                                      color: Color(0xFFADB5BD),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.1),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(chartData.length, (index) {
                        final val =
                            (chartData[index]['value'] as num).toDouble();
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: val,
                              color: const Color(0xFF212529),
                              width: 8,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: false,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),

                  // Layer 2: Line Chart (Interaction Layer + Previous Dots)
                  LineChart(
                    LineChartData(
                      minX: -0.5,
                      maxX: chartData.length.toDouble() - 0.5,
                      minY: 0,
                      maxY: maxY,
                      titlesData: FlTitlesData(
                        show: true, // Enable titles to reserve space
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize:
                                40, // Match BarChart reserved size exactly
                            getTitlesWidget: (value, meta) {
                              return const SizedBox
                                  .shrink(); // Don't draw text, just reserve space
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 8,
                          tooltipMargin: -60,
                          tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          tooltipBgColor: Colors.black.withOpacity(0.7),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((touchedSpot) {
                              // Only show tooltip for the Max Line (which triggers interaction)
                              // We assume the Max Line is the LAST one added.
                              // But properly, we should check barIndex or properties.
                              // Actually, if we touch, we might hit both red dot and max line.
                              // We only want ONE tooltip item.

                              // Logic: Find the spot that corresponds to the max line (y ~= maxY)
                              // OR just use the index from any touched spot to lookup data.

                              // Let's filter: only return an item if it's the Max Line (assumed index 1)
                              // Or simply ignore the specific spot data and return the content based on X index.

                              // IMPORTANT: If we return multiple items, they stack. We want one.
                              // So loop through spots, if we find one, generate content and return it,
                              // for others return null.

                              // Simplified: Always return ONE tooltip item per X index.
                              // Filter touchedSpots to find the one with the highest Y (which implies MaxLine)?
                              // Or if barIndex == 1.

                              if (touchedSpot.barIndex == 0)
                                return null; // Hide tooltip for red dots

                              final index = touchedSpot.x.toInt();
                              if (index < 0 || index >= chartData.length)
                                return null;

                              final dataItem = chartData[index];
                              final label = dataItem['label'];
                              final currentVal =
                                  (dataItem['value'] as num).toDouble();
                              final prevVal = (dataItem['prev_value'] as num?)
                                      ?.toDouble() ??
                                  0.0;

                              return LineTooltipItem(
                                '$label\n',
                                const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                children: [
                                  TextSpan(
                                    text: '今回: ${currentVal.toInt()}人\n',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '前回: ${prevVal.toInt()}人',
                                    style: const TextStyle(
                                      color: Color(0xFFADB5BD),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        // Line 0: Previous Value (Red Dots)
                        LineChartBarData(
                          spots: List.generate(chartData.length, (index) {
                            final prevVal =
                                (chartData[index]['prev_value'] as num?)
                                        ?.toDouble() ??
                                    0.0;
                            return FlSpot(index.toDouble(), prevVal);
                          }),
                          isCurved: false,
                          color: Colors.transparent, // Invisible line
                          barWidth: 0,
                          dotData: FlDotData(
                            show: true,
                            checkToShowDot: (spot, barData) {
                              return spot.y != 0; // Hide dots if value is 0
                            },
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 2.0,
                                color: const Color(
                                    0xFFFF6B6B), // Reddish-orange from image
                                strokeWidth: 1.0,
                                strokeColor: const Color(0xFFFF6B6B),
                              );
                            },
                          ),
                          belowBarData: BarAreaData(show: false),
                        ),
                        // Line 1: Invisible Max Height Line for Interaction
                        LineChartBarData(
                          spots: List.generate(chartData.length, (index) {
                            return FlSpot(index.toDouble(), maxY);
                          }),
                          color: Colors.transparent,
                          barWidth: 0,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isCircle,
  }) {
    return Row(
      children: [
        Container(
          width: isCircle ? 8 : 12,
          height: isCircle ? 8 : 4,
          decoration: BoxDecoration(
            color: color,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
