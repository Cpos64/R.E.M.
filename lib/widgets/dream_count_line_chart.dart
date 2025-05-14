import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DreamCountLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> buckets;
  final List<DateTime> days;

  const DreamCountLineChart({
    Key? key,
    required this.buckets,
    required this.days,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (days.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt().clamp(0, days.length - 1);
                final d = days[idx];
                return Text('${d.month}/${d.day}');
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: List.generate(days.length, (i) {
              final count = buckets[i]['totalCount'] as int;
              return FlSpot(i.toDouble(), count.toDouble());
            }),
          ),
        ],
      ),
    );
  }
}
