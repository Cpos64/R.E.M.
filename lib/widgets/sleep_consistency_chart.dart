import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SleepConsistencyChart extends StatelessWidget {
  final List<Map<String, dynamic>?> buckets;
  final List<DateTime> days;

  const SleepConsistencyChart({
    Key? key,
    required this.buckets,
    required this.days,
  }) : super(key: key);

  /// Parse either an ISO timestamp or a "h:mm a" string into a decimal hour.
  double _parseTime(String? text) {
    if (text == null || text.isEmpty) return 0.0;
    final iso = DateTime.tryParse(text);
    if (iso != null) {
      return iso.hour + iso.minute / 60.0;
    }
    try {
      final dt = DateFormat.jm().parse(text);
      return dt.hour + dt.minute / 60.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Two-column tooltip builder unchanged
  Widget _buildTwoColumnTooltip({
    required DateTime date,
    required String leftLabel,
    required String leftTime,
    required String rightLabel,
    required String rightTime,
  }) {
    final dateStr = DateFormat.MMMMd().format(date);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dateStr, style: TextStyle(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leftTime, style: TextStyle(color: Colors.white, fontSize: 12)),
                    Text(leftLabel, style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(rightTime, style: TextStyle(color: Colors.white, fontSize: 12)),
                    Text(rightLabel, style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    // how many days between labels
final step = days.length <= 7
  ? 1
  : (days.length / 6).ceil();

    // 1️⃣ Compute averages over only entered days
    final valid = buckets.where((e) => e != null).cast<Map<String, dynamic>>().toList();
    double sumBed = 0, sumAsleep = 0, sumWake = 0;
    for (var e in valid) {
      final rawBed = _parseTime(e['timeInBed'] as String?);
      final bedRel = rawBed > 12 ? rawBed - 24 : rawBed;
      sumBed += bedRel;
      final rawAsleep = _parseTime(e['timeAsleep'] as String?);
      final asleepRel = rawAsleep > 12 ? rawAsleep - 24 : rawAsleep;
      sumAsleep += asleepRel;
      final wakeRel = _parseTime(e['timeAwake'] as String?);
      sumWake += wakeRel;
    }
    final avgBed = valid.isEmpty ? 0.0 : sumBed / valid.length;
    final avgAsleep = valid.isEmpty ? 0.0 : sumAsleep / valid.length;
    final avgWake = valid.isEmpty ? 0.0 : sumWake / valid.length;

    // Format times
    String _fmt(double v) {
      final h = v.floor();
      final m = ((v - h) * 60).round();
      return DateFormat.jm().format(DateTime(0, 0, 0, h, m));
    }
    final avgBedStr = _fmt(avgBed);
    final avgAsleepStr = _fmt(avgAsleep);
    final avgWakeStr = _fmt(avgWake);

    // 2️⃣ Build rods from buckets & days
    final rods = <BarChartGroupData>[];
    for (var i = 0; i < days.length; i++) {
      final entry = buckets[i];
      if (entry != null) {
        final rawBed = _parseTime(entry['timeInBed'] as String?);
        final bedRel = rawBed > 12 ? rawBed - 24 : rawBed;
        final rawAsleep = _parseTime(entry['timeAsleep'] as String?);
        final asleepRel = rawAsleep > 12 ? rawAsleep - 24 : rawAsleep;
        final wakeRel = _parseTime(entry['timeAwake'] as String?);
        rods.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                fromY: bedRel,
                toY: asleepRel,
                width: 10,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              BarChartRodData(
                fromY: asleepRel,
                toY: wakeRel,
                width: 10,
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        );
      } else {
        rods.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(fromY: 0, toY: 0, width: 10, color: Colors.transparent),
              BarChartRodData(fromY: 0, toY: 0, width: 10, color: Colors.transparent),
            ],
          ),
        );
      }
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'Sleep Consistency',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 0),
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipPadding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    tooltipMargin: 4,
                    getTooltipColor: (_) => Colors.grey[900]!.withOpacity(0.9),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final date = days[group.x.toInt()];
                      final entry = buckets[group.x.toInt()] ?? {};
                      String fmtTime(String? raw) {
                        if (raw == null || raw.isEmpty) return '—';
                        final iso = DateTime.tryParse(raw);
                        String out;
                        if (iso != null) {
                          out = DateFormat.jm().format(iso);
                        } else {
                          try {
                            out = DateFormat.jm().format(DateFormat.jm().parse(raw));
                          } catch (_) {
                            return raw;
                          }
                        }
                        return out.replaceAll(' ', '\u00A0');
                      }
                      final bed = fmtTime(entry['timeInBed'] as String?);
                      final asleep = fmtTime(entry['timeAsleep'] as String?);
                      final wake = fmtTime(entry['timeAwake'] as String?);
                      final leftTime = rodIndex == 0 ? bed : asleep;
                      final rightTime = rodIndex == 0 ? asleep : wake;
                      final leftLabel = rodIndex == 0 ? 'Bedtime' : 'Asleep';
                      final rightLabel = rodIndex == 0 ? 'Asleep' : 'Wake';
                      return BarTooltipItem(
                        '',
                        const TextStyle(),
                        children: [
                          TextSpan(
                            text: '${DateFormat.MMMMd().format(date)}\n',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 10),
                          ),
                          TextSpan(
                            text: '$leftTime\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0$rightTime\n',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: '$leftLabel\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0$rightLabel',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                alignment: BarChartAlignment.spaceAround,
                groupsSpace: 4,
                minY: -6,
                maxY: 12,
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
                      interval: 6,
                      reservedSize: 40,
                      getTitlesWidget: (val, _) {
                        final hour = ((val % 24) + 24) % 24;
                        Widget label;
                        if (hour == 0) label = const Text('12 AM', style: TextStyle(fontSize: 10));
                        else if (hour == 6) label = const Text('6 AM', style: TextStyle(fontSize: 10));
                        else if (hour == 12) label = const Text('12 PM', style: TextStyle(fontSize: 10));
                        else if (hour == 18) label = const Text('6 PM', style: TextStyle(fontSize: 10));
                        else label = const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: label,
                        );
                      },
                    ),
                  ),
bottomTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    interval: step.toDouble(),
    getTitlesWidget: (value, _) {
      final idx = value.toInt();
      // 1) out of range?
      if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
      // 2) only every `step`-th bar
      if (idx % step != 0) return const SizedBox.shrink();
      // 3) format as M/d
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
                rangeAnnotations: RangeAnnotations(
                  horizontalRangeAnnotations: [
                    HorizontalRangeAnnotation(
                      y1: avgBed,
                      y2: avgAsleep,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.15),
                    ),
                  ],
                ),
                extraLinesData: ExtraLinesData(
                  extraLinesOnTop: false,
                  horizontalLines: [
                    HorizontalLine(
                      y: avgBed,
                      color: Colors.white,
                      strokeWidth: 1,
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.bottomLeft,
                        labelResolver: (_) => avgBedStr,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                    HorizontalLine(
                      y: avgAsleep,
                      color: Colors.white,
                      strokeWidth: 1,
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topLeft,
                        labelResolver: (_) => avgAsleepStr,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                    HorizontalLine(
                      y: avgWake,
                      color: Colors.white,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.bottomLeft,
                        labelResolver: (_) => avgWakeStr,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
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
