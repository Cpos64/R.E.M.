import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SleepStageBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> sleepData;

  const SleepStageBarChart({super.key, required this.sleepData});

  double _parseToMinutes(dynamic duration) {
    if (duration == null) return 0.0;

    final durationStr = duration.toString();

    if (RegExp(r'^\d+$').hasMatch(durationStr)) {
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
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < sleepData.length; i++) {
      final data = sleepData[i];

      final deep = _parseToMinutes(data['deepSleep']);
      final rem = _parseToMinutes(data['remSleep']);
      final light = _parseToMinutes(data['lightSleep']);
      final awake = _parseToMinutes(data['awakeTime']);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: deep + rem + light + awake,
              rodStackItems: [
                BarChartRodStackItem(0, deep, const Color(0xFF80CBC4)),   // Deep
                BarChartRodStackItem(deep, deep + rem, const Color(0xFFCE93D8)), // REM
                BarChartRodStackItem(deep + rem, deep + rem + light, const Color(0xFFFFF59D)), // Light
                BarChartRodStackItem(deep + rem + light, deep + rem + light + awake, const Color(0xFFE57373)), // Awake
              ],
              width: 18,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 24.0),
      child: SizedBox(
        height: 420,
        child: BarChart(
          BarChartData(
            barGroups: barGroups,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 60,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final hours = value ~/ 60;
                    final minutes = value % 60;
                    return Text(
                      minutes == 0 ? '${hours}h' : '${hours}h${minutes}m',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
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
            borderData: FlBorderData(show: true),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              horizontalInterval: 60,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.white24, strokeWidth: 0.5),
            ),
            barTouchData: BarTouchData(enabled: true),
          ),
        ),
      ),
    );
  }
}
