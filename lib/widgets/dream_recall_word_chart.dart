import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DreamRecallWordChart extends StatelessWidget {
  final List<Map<String, dynamic>> buckets;

  const DreamRecallWordChart({
    Key? key,
    required this.buckets,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Flatten each (recallRating, wordCount) into a ScatterSpot
    final spots = <ScatterSpot>[];
    for (var b in buckets) {
      final ratings = b['recallRatings'] as List<int>;
      final words   = b['wordCounts']    as List<int>;
      for (var j = 0; j < ratings.length; j++) {
        spots.add(ScatterSpot(
          ratings[j].toDouble(),
          words[j].toDouble(),
          dotPainter: FlDotCirclePainter(radius: 4),
        ));
      }
    }

    return ScatterChart(
      ScatterChartData(
        minX: 0,
        maxX: 10,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
        ),
        scatterSpots: spots,
      ),
    );
  }
}
