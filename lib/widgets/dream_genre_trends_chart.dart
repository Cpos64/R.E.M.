import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../dream_genres.dart';

class DreamGenreTrendsChart extends StatelessWidget {
  final List<Map<String, dynamic>> buckets;
  final List<DateTime> days;

  const DreamGenreTrendsChart({
    Key? key,
    required this.buckets,
    required this.days,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Collect all unique genres across days and preserve
    // the ordering from [dreamGenres] for consistent colors
    final used = <String>{};
    for (var b in buckets) {
      used.addAll((b['genreCounts'] as Map<String, int>).keys);
    }
    final genreList = dreamGenres.where((g) => used.contains(g)).toList();

    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: days.isNotEmpty,
              interval: 1,
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
          final counts = buckets[i]['genreCounts'] as Map<String, int>;
          double runningTotal = 0;
          final rods = <BarChartRodStackItem>[];

          for (var g in genreList) {
            final c = counts[g] ?? 0;
            rods.add(BarChartRodStackItem(
              runningTotal,
              runningTotal + c,
              genreColors[g] ?? Colors.grey,
            ));
            runningTotal += c;
          }

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: runningTotal,
                rodStackItems: rods,
                width: 12,
              ),
            ],
          );
        }),
      ),
    );
  }
}
