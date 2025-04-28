import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SleepConsistencyChart extends StatelessWidget {
  final List<Map<String, dynamic>> sleepData;

  const SleepConsistencyChart({
    Key? key,
    required this.sleepData,
  }) : super(key: key);

  /// Parse "10:30 PM" → 22.5, "6:15 AM" → 6.25
  double _parseTime(String? text) {
    if (text == null || text.isEmpty) return 0.0;
    try {
      final dt = DateFormat.jm().parse(text);
      return dt.hour + dt.minute / 60.0;
    } catch (_) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build two bars per day: (in-bed → asleep) + (asleep → wake)
    final rods = <BarChartGroupData>[];
    double sumBed = 0, sumWake = 0;

    for (var i = 0; i < sleepData.length; i++) {
      final e = sleepData[i];
      final bed    = _parseTime(e['timeInBed']   as String?);
      final asleep = _parseTime(e['timeAsleep']  as String?);
      final wake   = _parseTime(e['timeAwake']   as String?);

      // shift pre-midnight into the negative so 0 == midnight
      final bedRel    = bed - 24;    // e.g. 22.0 → -2.0
      final asleepRel = asleep - 24; // e.g. 22.5 → -1.5
      final wakeRel   = wake;        // e.g.  6.0 → +6.0

      rods.add(BarChartGroupData(
        x: i,
        barRods: [
          // semi-transparent bar: in-bed → asleep
          BarChartRodData(
            fromY: bedRel,
            toY:   asleepRel,
            width: 10,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          // solid bar: asleep → wake
          BarChartRodData(
            fromY: asleepRel,
            toY:   wakeRel,
            width: 10,
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ));

      sumBed  += bedRel;
      sumWake += wakeRel;
    }

    final avgBed  = sumBed  / sleepData.length;
    final avgWake = sumWake / sleepData.length;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'Sleep Consistency',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // The BarChart itself fills the remaining height from the pager's SizedBox( height:380 )
        Expanded(
          child: BarChart(
            BarChartData(
              minY: -6,   // 18:00 → -6.0
              maxY: 12,   // 12:00 → +12.0
              barGroups: rods,

              gridData: FlGridData(
                show: true,
                horizontalInterval: 3,
                verticalInterval: 1,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white24, strokeWidth: 0.5),
                getDrawingVerticalLine: (_) =>
                    const FlLine(color: Colors.white24, strokeWidth: 0.5),
              ),

              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 6,       // only every 6 hours
                    reservedSize: 40,
                    getTitlesWidget: (val, _) {
                      final hour = (val % 24 + 24) % 24;
                      if (hour == 0)  return const Text('12 AM', style: TextStyle(fontSize: 10));
                      if (hour == 6)  return const Text('6 AM',  style: TextStyle(fontSize: 10));
                      if (hour == 12) return const Text('12 PM', style: TextStyle(fontSize: 10));
                      if (hour == 18) return const Text('6 PM',  style: TextStyle(fontSize: 10));
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (val, _) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= sleepData.length) return const SizedBox.shrink();
                      final dt = sleepData[idx]['date'] as DateTime;
                      return Text(DateFormat('E').format(dt), style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),

                topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),

              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: avgBed,
                  color: Colors.white,
                  strokeWidth: 1,
                  dashArray: null, // solid
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topLeft,
                    labelResolver: (_) => 'Avg Bedtime',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
                HorizontalLine(
                  y: avgWake,
                  color: Colors.white,
                  strokeWidth: 1,
                  dashArray: [4, 4], // dashed
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.bottomLeft,
                    labelResolver: (_) => 'Avg Wake',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ]),

              borderData: FlBorderData(show: true),
            ),
          ),
        ),

        const SizedBox(height: 8),
        // ── Legend ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                label: 'In Bed → Asleep',
              ),
              const SizedBox(width: 16),
              _LegendDot(
                color: Theme.of(context).colorScheme.primary,
                label: 'Asleep → Wake',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}
