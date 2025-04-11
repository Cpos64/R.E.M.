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

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
  minX: 0,
  maxX: sleepData.length > 1 ? (sleepData.length - 1).toDouble() : 1,
  minY: 0,
  titlesData: FlTitlesData(
    leftTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: 1, // Only show one label per index
        getTitlesWidget: (value, meta) {
          int index = value.toInt();
          if (index < 0 || index >= sleepData.length) return const SizedBox();
          final date = sleepData[index]['date'] as DateTime;
          return Text(
            DateFormat('E').format(date), // e.g., Mon, Tue
            style: TextStyle(fontSize: 10),
          );
        },
      ),
    ),
  ),
  gridData: FlGridData(show: true),
  borderData: FlBorderData(show: true),
lineBarsData: [
  if (showOnlyTotal)
    LineChartBarData(
      spots: totalSleepSpots,
      isCurved: false,
      color: Colors.blue,
      dotData: FlDotData(show: false),
      barWidth: 2,
    )
  else ...[
    if (deepSleepSpots.isNotEmpty)
      LineChartBarData(
        spots: deepSleepSpots,
        isCurved: false,
        color: Colors.green,
        dotData: FlDotData(show: false),
        barWidth: 2,
      ),
    if (remSleepSpots.isNotEmpty)
      LineChartBarData(
        spots: remSleepSpots,
        isCurved: false,
        color: Colors.purple,
        dotData: FlDotData(show: false),
        barWidth: 2,
      ),
    if (awakeSpots.isNotEmpty)
      LineChartBarData(
        spots: awakeSpots,
        isCurved: false,
        color: Colors.red,
        dotData: FlDotData(show: false),
        barWidth: 2,
      ),
  ],
],
)
      ),
    );
  }
}
