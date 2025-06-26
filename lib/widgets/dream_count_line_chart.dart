import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

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

    // find the max dream-count so we can size the Y-axis
    final maxCount = buckets.fold<int>(
      0,
      (prev, e) => math.max(prev, e['totalCount'] as int),
    );
    final maxY = (maxCount + 1).toDouble();

    // we want at most ~7 labels, evenly spaced
    final step = days.length <= 7 ? 1 : (days.length / 6).ceil();

    return Padding(
      // add a bit of breathing-room on the left so axis labels don't clip
      padding: const EdgeInsets.only(left: 16),
      child: TweenAnimationBuilder<double>(
        // a UniqueKey forces the tween to restart any time this widget
        // is re-built (e.g. when you switch tabs)
        key: UniqueKey(),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (context, anim, _) {
          return BarChart(
            BarChartData(
              minY: 0,
              maxY: maxY,
              // remove the default chart border
              borderData: FlBorderData(show: false),

              titlesData: FlTitlesData(
                // left-side (Y) labels
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 28,
                    getTitlesWidget: (value, _) =>
                        Text(value.toInt().toString()),
                  ),
                ),

                // bottom (X) labels
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: showTitles,
                    interval: step.toDouble(),
                    getTitlesWidget: (value, _) {
                      if (!showTitles) return const SizedBox.shrink();
                      final idx = value.toInt().clamp(0, days.length - 1);
                      if (idx % step != 0) return const SizedBox.shrink();
                      final d = days[idx];
                      return Text(
                        '${d.month}/${d.day}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),

                // explicitly hide the top & right axes
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),

              // the bars themselves
              barGroups: List.generate(days.length, (i) {
                final count = buckets[i]['totalCount'] as int;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: count * anim,
                      width: 12,
                      borderRadius: BorderRadius.circular(2),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
