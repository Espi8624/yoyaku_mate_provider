import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DynamicChartCard extends StatelessWidget {
  final List<dynamic>? chartData;

  const DynamicChartCard({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    if (chartData == null || chartData!.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('データがありません'),
      );
    }

    // Determine max Y including both current and previous values
    double maxY = 10.0;
    if (chartData!.isNotEmpty) {
      final maxVal = chartData!
          .map((e) => (e['value'] as num).toDouble())
          .reduce((curr, next) => curr > next ? curr : next);
      final maxPrev = chartData!
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
                      alignment: BarChartAlignment.spaceAround,
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
                              if (index >= 0 && index < chartData!.length) {
                                // Reduce labels if too many data points
                                if (chartData!.length > 10 && index % 2 != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    chartData![index]['label'].toString(),
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
                      barGroups: List.generate(chartData!.length, (index) {
                        final val =
                            (chartData![index]['value'] as num).toDouble();
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
                      maxX: chartData!.length.toDouble() - 0.5,
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
                              if (touchedSpot.barIndex == 0) return null;

                              final index = touchedSpot.x.toInt();
                              if (index < 0 || index >= chartData!.length)
                                return null;

                              final dataItem = chartData![index];
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
                          spots: List.generate(chartData!.length, (index) {
                            final prevVal =
                                (chartData![index]['prev_value'] as num?)
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
                          spots: List.generate(chartData!.length, (index) {
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

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isCircle,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: isCircle ? 12 : 4,
          decoration: BoxDecoration(
            color: color,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF868E96),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
