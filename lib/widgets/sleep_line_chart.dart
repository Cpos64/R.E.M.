import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SleepLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> sleepData;
  final bool showOnlyTotal;

  const SleepLineChart({
    super.key,
    required this.sleepData,
    this.showOnlyTotal = false,
  });

  double _parseToMinutes(dynamic duration) {
    if (duration == null) return 0.0;

    final durationStr = duration.toString();

    // Handle if the value is a plain number of minutes like 420
    if (RegExp(r'^\d+\$').hasMatch(durationStr)) {
      return double.tryParse(durationStr) ?? 0.0;
    }

    final hours = RegExp(r'(\d+)h').firstMatch(durationStr)?.group(1);
    final minutes = RegExp(r'(\d+)m').firstMatch(durationStr)?.group(1);

    final totalMinutes = (int.tryParse(hours ?? '0') ?? 0) * 60 +
        (int.tryParse(minutes ?? '0') ?? 0);

    return totalMinutes.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    List<FlSpot> totalSleepSpots = [];
    List<FlSpot> deepSleepSpots = [];
    List<FlSpot> remSleepSpots = [];
    List<FlSpot> awakeSpots = [];

    for (int i = 0; i < sleepData.length; i++) {
      final log = sleepData[i];

      final total = _parseToMinutes(log['totalSleep']);
      if (total > 0) totalSleepSpots.add(FlSpot(i.toDouble(), total));

      final deep = _parseToMinutes(log['deepSleep']);
      if (deep > 0) deepSleepSpots.add(FlSpot(i.toDouble(), deep));

      final rem = _parseToMinutes(log['remSleep']);
      if (rem > 0) remSleepSpots.add(FlSpot(i.toDouble(), rem));

      final awake = _parseToMinutes(log['awakeTime']);
      if (awake > 0) awakeSpots.add(FlSpot(i.toDouble(), awake));
    }

    final allYValues = showOnlyTotal
        ? totalSleepSpots
        : [...deepSleepSpots, ...remSleepSpots, ...awakeSpots];

    double findMinY() =>
        allYValues.map((e) => e.y).fold<double>(9999, (a, b) => a < b ? a : b);
    double findMaxY() =>
        allYValues.map((e) => e.y).fold<double>(0, (a, b) => a > b ? a : b);

    final minY = (findMinY() - 30).clamp(0.0, double.infinity);
    final maxY = findMaxY() + 30;

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 285,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: LineChart(
                  LineChartData(
                    clipData: FlClipData(
                      top: false,
                      bottom: false,
                      left: false,
                      right: false,
                    ),
                    minX: 0,
                    maxX: sleepData.length > 1
                        ? (sleepData.length - 1).toDouble() + 0.3
                        : 1.0,
                    minY: minY,
                    maxY: maxY,
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          interval: 60.0,
                          getTitlesWidget: (value, meta) {
                            int totalMinutes = value.toInt();
                            int hours = totalMinutes ~/ 60;
                            int minutes = totalMinutes % 60;

                            return Text(
                              minutes == 0 ? '${hours}h' : '${hours}h${minutes}m',
                              style: TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index < 0 || index >= sleepData.length) return const SizedBox();
                            final date = sleepData[index]['date'] as DateTime;
                            return Text(
                              DateFormat('E').format(date),
                              style: TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.blueAccent,
                        fitInsideHorizontally: true,
                        showOnTopOfTheChartBoxArea: true,
                        tooltipMargin: 16,
                        getTooltipItems: (touchedSpots) {
                          if (touchedSpots.isEmpty) return [];

                          final spot = touchedSpots.first;
                          final index = spot.x.toInt();
                          final date = sleepData[index]['date'] as DateTime;

                          if (showOnlyTotal) {
                            final total = sleepData[index]['totalSleep'];
                            return [
                              LineTooltipItem(
                                '${DateFormat('E').format(date)}\nTotal: $total',
                                const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ];
                          }

                          final deepSleep = sleepData[index]['deepSleep'];
                          final remSleep = sleepData[index]['remSleep'];
                          final awakeTime = sleepData[index]['awakeTime'];

                          return [
                            LineTooltipItem(
                              '${DateFormat('E').format(date)}\n'
                              'Deep: ${deepSleep}m\n'
                              'REM: ${remSleep}m\n'
                              'Awake: ${awakeTime}m',
                              const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ];
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      verticalInterval: 1.0,
                      drawHorizontalLine: true,
                      horizontalInterval: 60.0,
                      getDrawingVerticalLine: (value) => FlLine(
                        color: const Color(0xFFBDBDBD),
                        strokeWidth: 0.5,
                      ),
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: const Color(0xFFBDBDBD),
                        strokeWidth: 0.5,
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      if (showOnlyTotal)
                        LineChartBarData(
                          spots: totalSleepSpots,
                          isCurved: false,
                          color: Color(0xFF64B5F6),
                          dotData: FlDotData(show: true),
                          barWidth: 2,
                        )
                      else ...[
                        if (deepSleepSpots.isNotEmpty)
                          LineChartBarData(
                            spots: deepSleepSpots,
                            isCurved: false,
                            color: Color(0xFF80CBC4),
                            dotData: FlDotData(show: true),
                            barWidth: 2,
                          ),
                        if (remSleepSpots.isNotEmpty)
                          LineChartBarData(
                            spots: remSleepSpots,
                            isCurved: false,
                            color: Color(0xFFCE93D8),
                            dotData: FlDotData(show: true),
                            barWidth: 2,
                          ),
                        if (awakeSpots.isNotEmpty)
                          LineChartBarData(
                            spots: awakeSpots,
                            isCurved: false,
                            color: Color(0xFFE57373),
                            dotData: FlDotData(show: true),
                            barWidth: 2,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (!showOnlyTotal)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LegendItemDot(label: 'Deep', color: Color(0xFF80CBC4)),
                    SizedBox(width: 16),
                    LegendItemDot(label: 'REM', color: Color(0xFFCE93D8)),
                    SizedBox(width: 16),
                    LegendItemDot(label: 'Awake', color: Color(0xFFE57373)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LegendItemDot extends StatelessWidget {
  final String label;
  final Color color;

  const LegendItemDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.white)),
      ],
    );
  }
}
