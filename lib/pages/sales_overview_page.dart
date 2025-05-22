import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesOverviewPage extends StatefulWidget {
  const SalesOverviewPage({super.key});

  @override
  State<SalesOverviewPage> createState() => _SalesOverviewPageState();
}

class _SalesOverviewPageState extends State<SalesOverviewPage> {
  int selectedReport = 0; // 0:일간, 1:월간, 2:연간
  int selectedType = 0;

  final List<String> typeButtons = ["売上", "支出"];
  final List<String> reportTitles = ["日間", "月間", "年間"];
  final List<String> reportContents = [
    "今月売出１２０万円、先月比５％減少\n主要原因: 昼時間帯客が減少\n提案: 夜時間帯割引イベント考慮",
    "今月売出３５００円、先月比２％増加\n主要原因: 週末売出上昇\n提案: 平日イベント拡大",
    "今年売出４億２千万円、先年比８％増加\n主要原因: 新規メニューが人気\n提案: 新メニューのプロモーション強化",
  ];

  static const graphTitleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 19,
    color: Color(0xFF263238),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // 좌측 2/3
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.only(left: 24, top: 24, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 타이틀 (스크롤 영역 밖)
                  const Text(
                    "売上照会",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 매출/지출 선택 버튼 (스크롤 영역 밖)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: List.generate(2, (idx) {
                        return Padding(
                          padding: EdgeInsets.only(left: idx == 1 ? 4 : 0),
                          child: SizedBox(
                            width: 120,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedType == idx
                                    ? const Color(0xFF263238)
                                    : Colors.white,
                                foregroundColor: selectedType == idx
                                    ? Colors.white
                                    : const Color(0xFF263238),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                    color: Color(0xFF263238),
                                    width: 1,
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedType = idx;
                                });
                              },
                              child: Text(
                                typeButtons[idx],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 스크롤 가능한 컨텐츠 영역
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 매출 요약
                          Row(
                            children: [
                              Expanded(
                                child: _summaryBox(
                                  title: "本日の売上",
                                  value: "5,000",
                                  sub: "前日比 5%増",
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _summaryBox(
                                  title: "今週売上",
                                  value: "200,000",
                                  sub: "先週比 3%減",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // 일별 그래프
                          const Text("日別グラフ", style: graphTitleStyle),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 300,
                            child: _sectionBox(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: const FlTitlesData(
                                      rightTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: const [
                                          FlSpot(0, 3),
                                          FlSpot(1, 1),
                                          FlSpot(2, 4),
                                          FlSpot(3, 2),
                                          FlSpot(4, 5),
                                          FlSpot(5, 3),
                                          FlSpot(6, 4),
                                        ],
                                        isCurved: true,
                                        color: const Color(0xFF263238),
                                        barWidth: 2,
                                        dotData: const FlDotData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 시간대별 그래프
                          const Text("時間帯別グラフ", style: graphTitleStyle),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 300,
                            child: _sectionBox(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: BarChart(
                                  BarChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: const FlTitlesData(
                                      rightTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: [
                                      BarChartGroupData(
                                        x: 0,
                                        barRods: [
                                          BarChartRodData(
                                            toY: 8,
                                            color: const Color(0xFF263238),
                                            width: 20,
                                          )
                                        ],
                                      ),
                                      BarChartGroupData(
                                        x: 1,
                                        barRods: [
                                          BarChartRodData(
                                            toY: 10,
                                            color: const Color(0xFF263238),
                                            width: 20,
                                          )
                                        ],
                                      ),
                                      BarChartGroupData(
                                        x: 2,
                                        barRods: [
                                          BarChartRodData(
                                            toY: 14,
                                            color: const Color(0xFF263238),
                                            width: 20,
                                          )
                                        ],
                                      ),
                                      BarChartGroupData(
                                        x: 3,
                                        barRods: [
                                          BarChartRodData(
                                            toY: 15,
                                            color: const Color(0xFF263238),
                                            width: 20,
                                          )
                                        ],
                                      ),
                                      BarChartGroupData(
                                        x: 4,
                                        barRods: [
                                          BarChartRodData(
                                            toY: 13,
                                            color: const Color(0xFF263238),
                                            width: 20,
                                          )
                                        ],
                                      ),
                                      BarChartGroupData(
                                        x: 5,
                                        barRods: [
                                          BarChartRodData(
                                            toY: 10,
                                            color: const Color(0xFF263238),
                                            width: 20,
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 구분선
          Container(
            width: 1,
            color: Colors.grey[300],
          ),
          // 우측 1/3
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "売上レポート",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 레포트 버튼
                  Row(
                    children: List.generate(3, (idx) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: idx == 1 ? 4 : 0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedReport == idx
                                  ? const Color(0xFF263238)
                                  : Colors.white,
                              foregroundColor: selectedReport == idx
                                  ? Colors.white
                                  : const Color(0xFF263238),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(
                                  color: Color(0xFF263238),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedReport = idx;
                              });
                            },
                            child: Text(
                              reportTitles[idx],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  // 레포트 내용
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        reportContents[selectedReport],
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF263238),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox({
    required String title,
    required String value,
    String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF263238)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  Widget _sectionBox({Widget? child}) {
    return Container(
      width: double.infinity,
      decoration: _boxDecoration(),
      child: child,
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
