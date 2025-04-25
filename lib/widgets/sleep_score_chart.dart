import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SleepScoreChart extends StatelessWidget {
  final List<Map<String, dynamic>> sleepData;

  const SleepScoreChart({
    super.key,
    required this.sleepData,
  });

  @override
  Widget build(BuildContext context) {
    List<FlSpot> sleepScoreSpots = [];

    for (int i = 0; i < sleepData.length; i++) {
      final score = sleepData[i]['sleepScore'] ?? 0;
      sleepScoreSpots.add(FlSpot(i.toDouble(), score.toDouble()));
    }

    final minY = sleepScoreSpots.map((e) => e.y).fold<double>(100, (a, b) => a < b ? a : b) - 10;
    final maxY = sleepScoreSpots.map((e) => e.y).fold<double>(0, (a, b) => a > b ? a : b) + 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: LineChart(
                  LineChartData(
                    clipData: FlClipData.all(),
                    minX: 0,
                    maxX: sleepScoreSpots.length > 1
                        ? (sleepScoreSpots.length - 1).toDouble() + 0.3
                        : 1.0,
                    minY: minY.clamp(0.0, 100.0),
                    maxY: maxY.clamp(0.0, 100.0),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          reservedSize: 40,
                          getTitlesWidget: (value, _) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, _) {
                            int index = value.toInt();
                            if (index < 0 || index >= sleepData.length) return const SizedBox();
                            final date = sleepData[index]['date'] as DateTime;
                            return Text(
                              DateFormat('E').format(date),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      horizontalInterval: 20,
                      verticalInterval: 1.0,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.white24,
                        strokeWidth: 0.5,
                      ),
                      getDrawingVerticalLine: (_) => FlLine(
                        color: Colors.white24,
                        strokeWidth: 0.5,
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      getTouchedSpotIndicator: (barData, indicators) {
                        return indicators.map((index) {
                          return TouchedSpotIndicatorData(
                            FlLine(color: Colors.white24, strokeWidth: 1),
                            FlDotData(show: true),
                          );
                        }).toList();
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
  if (touchedSpots.isEmpty) return [];
  final index = touchedSpots.first.x.toInt();
  final date = sleepData[index]['date'] as DateTime;
  final score = sleepData[index]['sleepScore'];
  return [
    LineTooltipItem(
      '${DateFormat('E').format(date)}\nScore: $score',
      const TextStyle(color: Colors.white, fontSize: 12),
    ),
  ];
}

                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: sleepScoreSpots,
                        isCurved: false,
                        color: const Color(0xFF64B5F6),
                        dotData: FlDotData(show: true),
                        barWidth: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
