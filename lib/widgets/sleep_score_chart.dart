import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ── 1) The core SleepScoreChart ───────────────────────────────────────────────
class SleepScoreChart extends StatelessWidget {
  final List<Map<String, dynamic>> sleepData;

  const SleepScoreChart({
    super.key,
    required this.sleepData,
  });

  @override
  Widget build(BuildContext context) {
    // 1) Fixed 7-day window
    final today = DateTime.now();
    final last7 = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    // 2) Map dates → scores
    final scores = List<double?>.filled(7, null);
    for (var entry in sleepData) {
      final dt = entry['date'] as DateTime;
      final idx = last7.indexWhere((d) =>
        d.year == dt.year && d.month == dt.month && d.day == dt.day);
      if (idx >= 0) {
        scores[idx] = (entry['sleepScore'] as num).toDouble();
      }
    }

    // 3) Build spots
    final spots = List<FlSpot>.generate(7, (i) {
      final v = scores[i];
      return FlSpot(i.toDouble(), v ?? double.nan);
    });

    // 4) Compute stats
    final valid = scores.where((s) => s != null).cast<double>().toList();
    final avg = valid.isEmpty
      ? 0.0
      : valid.reduce((a, b) => a + b) / valid.length;
    final minY = (valid.isEmpty ? 0.0 : valid.reduce((a, b) => a < b ? a : b)) - 10;
    final maxY = (valid.isEmpty ? 100.0 : valid.reduce((a, b) => a > b ? a : b)) + 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Sleep Score',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ),

        // Chart
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
            child: LineChart(
              LineChartData(
                clipData: FlClipData.all(),
                minX: 0,
                maxX: last7.length > 1
                    ? (last7.length - 1).toDouble() + 0.3
                    : 1.0,
                minY: minY.clamp(0.0, 100.0),
                maxY: maxY.clamp(0.0, 100.0),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    interval: 1,
    getTitlesWidget: (double value, TitleMeta meta) {
      // 1) only label exact integer positions
      if (value % 1 != 0) return const SizedBox();

      // 2) convert to index and guard range
      final idx = value.toInt();
      if (idx < 0 || idx >= last7.length) return const SizedBox();

      // 3) render the weekday
      return Text(
        DateFormat('E').format(last7[idx]),
        style: const TextStyle(fontSize: 10),
      );
    },
  ),
),

                  topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine:   true,
                  drawHorizontalLine: true,
                  horizontalInterval: 20,
                  verticalInterval:   1,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Colors.white24, strokeWidth: 0.5),
                  getDrawingVerticalLine: (_) =>
                      const FlLine(color: Colors.white24, strokeWidth: 0.5),
                ),

                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: avg,
                      color: Colors.white54,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (_) => 'Avg: ${avg.round()}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                  ],
                ),

                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (data, idxs) => idxs.map((i) =>
                    TouchedSpotIndicatorData(
                      FlLine(color: Colors.white24, strokeWidth: 1),
                      FlDotData(show: true),
                    )
                  ).toList(),
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      if (spots.isEmpty) return [];
                      final i = spots.first.x.toInt();
                      final dateStr = DateFormat('E, MMM d').format(last7[i]);
                      final score  = scores[i]?.round() ?? 0;
                      return [
                        LineTooltipItem(
                          '',
                          const TextStyle(),
                          children: [
                            TextSpan(
                              text: '$dateStr\n',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text: 'Score: ',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text: '$score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ];
                    },
                  ),
                ),

                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                ],

                borderData: FlBorderData(show: true),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ── 2) The fade-in wrapper ────────────────────────────────────────────────────
class FadingSleepScoreChart extends StatefulWidget {
  final List<Map<String, dynamic>> sleepData;

  const FadingSleepScoreChart({
    Key? key,
    required this.sleepData,
  }) : super(key: key);

  @override
  _FadingSleepScoreChartState createState() => _FadingSleepScoreChartState();
}

class _FadingSleepScoreChartState extends State<FadingSleepScoreChart> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _opacity = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      child: SleepScoreChart(sleepData: widget.sleepData),
    );
  }
}
