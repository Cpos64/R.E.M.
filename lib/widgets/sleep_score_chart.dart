import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ── 1) The core SleepScoreChart ───────────────────────────────────────────────
class SleepScoreChart extends StatelessWidget {
  final List<Map<String, dynamic>?> buckets;
  final List<DateTime> days;

  const SleepScoreChart({
    Key? key,
    required this.buckets,
    required this.days,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Thinning labels for longer windows
    final labelInterval = days.length <= 7 ? 1.0 : (days.length / 6).ceilToDouble();

    // Determine bucket size in days for tooltip ranges
    final bucketSize = days.length > 1
        ? days[1].difference(days[0]).inDays
        : 1;

    String formatRange(int idx) {
      final start = days[idx];
      if (bucketSize <= 1) {
        return DateFormat('E, MMM d').format(start);
      }
      final end = start.add(Duration(days: bucketSize - 1));
      final sameYear = start.year == end.year;
      final startFmt = DateFormat('MMM d').format(start);
      final endFmt = sameYear
          ? DateFormat('MMM d').format(end)
          : DateFormat('MMM d, yyyy').format(end);
      return '$startFmt - $endFmt';
    }

    // 1️⃣ Gather only the non-null score values and cast to double
    final scoreList = buckets
        .where((b) => b != null && b!['sleepScore'] != null)
        .map((b) => (b!['sleepScore'] as num).toDouble())
        .toList();

    // 2️⃣ Compute the average (or 0 if no data)
    final avgScore = scoreList.isEmpty
        ? 0.0
        : scoreList.reduce((a, b) => a + b) / scoreList.length;

    // 3️⃣ Build spots from buckets (casting to num then to double)
    final spots = <FlSpot>[];
    for (var i = 0; i < buckets.length; i++) {
      final entry = buckets[i];
      if (entry != null && entry['sleepScore'] != null) {
        final raw = entry['sleepScore'] as num;
        spots.add(FlSpot(i.toDouble(), raw.toDouble()));
      }
    }

    // 4️⃣ Compute chart bounds from scoreList
    final minY = scoreList.isEmpty
        ? 0.0
        : scoreList.reduce((a, b) => a < b ? a : b) - 10;
    final maxY = scoreList.isEmpty
        ? 100.0
        : scoreList.reduce((a, b) => a > b ? a : b) + 10;

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
                maxX: buckets.length > 1
                    ? (buckets.length - 1).toDouble() + 0.3
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
    interval: labelInterval,
    getTitlesWidget: (double value, TitleMeta meta) {
      if (value % 1 != 0) return const SizedBox();
      final idx = value.toInt();
      if (idx < 0 || idx >= days.length) return const SizedBox();
      // M/d gives e.g. 4/24, 5/2
      return Text(
        DateFormat('M/d').format(days[idx]),
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
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Colors.white24, strokeWidth: 0.5),
                  getDrawingVerticalLine: (_) =>
                      const FlLine(color: Colors.white24, strokeWidth: 0.5),
                ),

                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: avgScore,
                      color: Colors.white54,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                      label: HorizontalLineLabel(
                        show: false,
                        alignment: Alignment.topLeft,
                        labelResolver: (_) => 'Avg: ${avgScore.round()}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10),
                      ),
                    ),
                  ],
                ),

                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (data, idxs) => idxs
                      .map((i) => TouchedSpotIndicatorData(
                            FlLine(color: Colors.white24, strokeWidth: 1),
                            FlDotData(show: true),
                          ))
                      .toList(),
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    getTooltipItems: (spots) {
                      if (spots.isEmpty) return [];
                      final i = spots.first.x.toInt();
                      final dateStr = formatRange(i);
                      final scoreValue =
                          (buckets[i]?['sleepScore'] as num?)?.round() ?? 0;
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
                              text: '$scoreValue',
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
                      color: Theme.of(context).colorScheme.primary
                          .withOpacity(0.2),
                    ),
                  ),
                ],

                borderData: FlBorderData(show: false),
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
  final List<Map<String, dynamic>?> buckets;
  final List<DateTime> days;

  const FadingSleepScoreChart({
    Key? key,
    required this.buckets,
    required this.days,
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
      child: SleepScoreChart(
        buckets: widget.buckets,
        days: widget.days,
      ),
    );
  }
}
