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
    final showTitles = days.isNotEmpty;
    final interval = showTitles ? (days.length / 5).ceilToDouble() : 1.0;

    return BarChart(
      BarChartData(
        minY: 0,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showTitles,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (days.isEmpty) return const SizedBox.shrink();
                final idx = value.toInt().clamp(0, days.length - 1);
                final d = days[idx];
                return Text('${d.month}/${d.day}');
              },
            ),
          ),
        ),
        barGroups: List.generate(days.length, (i) {
          final count = buckets[i]['totalCount'] as int;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                width: 12,
                borderRadius: BorderRadius.circular(2),
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          );
        }),
      ),
    );
  }
}
