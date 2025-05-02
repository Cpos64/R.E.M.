import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SleepStageBarChart extends StatefulWidget {
  final List<Map<String, dynamic>?> buckets;
  final List<DateTime> days;

  const SleepStageBarChart({
    Key? key,
    required this.buckets,
    required this.days,
  }) : super(key: key);

  @override
  _SleepStageBarChartState createState() => _SleepStageBarChartState();
}

class _SleepStageBarChartState extends State<SleepStageBarChart> {
  int? touchedIndex;
  Offset? touchPosition;
  String? _touchedSegment; // 'dr' or 'la'

  double _parseToMinutes(dynamic duration) {
    if (duration == null) return 0.0;
    final s = duration.toString();
    final h = int.tryParse(RegExp(r'(\d+)h').firstMatch(s)?.group(1) ?? '') ?? 0;
    final m = int.tryParse(RegExp(r'(\d+)m').firstMatch(s)?.group(1) ?? '') ?? 0;
    return (h * 60 + m).toDouble();
  }

String _formatDuration(double minutes) {
  final h = minutes ~/ 60;
  final m = (minutes % 60).round();
  return h > 0 ? '${h}h${m}m' : '${m}m';
}


  Widget _buildTooltipRow(String key, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$key: ',
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

// how many days between labels
final step = widget.days.length <= 7
  ? 1
  : (widget.days.length / 6).ceil();


    // Build barGroups from buckets
    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < widget.buckets.length; i++) {
      final entry = widget.buckets[i] ?? {};
      final deep = _parseToMinutes(entry['deepSleep']);
      final rem = _parseToMinutes(entry['remSleep']);
      final light = _parseToMinutes(entry['lightSleep']);
      final awake = _parseToMinutes(entry['awakeTime']);
      final total = deep + rem + light + awake;
      const minVis = 0.1;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: total > 0 ? total : minVis,
              width: 18.0,
              borderRadius: BorderRadius.circular(2),
              rodStackItems: [
                BarChartRodStackItem(0, deep > 0 ? deep : minVis, const Color(0xFF80CBC4)),
                BarChartRodStackItem(deep, deep + (rem > 0 ? rem : minVis), const Color(0xFFCE93D8)),
                BarChartRodStackItem(deep + rem, deep + rem + (light > 0 ? light : minVis), const Color(0xFFFFF59D)),
                BarChartRodStackItem(deep + rem + light, total > 0 ? total : minVis, const Color(0xFFE57373)),
              ],
            ),
          ],
        ),
      );
    }

    // Compute averages from buckets
final valid = widget.buckets
    .where((e) => e != null)            // drop missing days
    .cast<Map<String, dynamic>>()       // they're non-null now
    .toList();

final totals = <double>[];
final restTotals = <double>[];

for (var entry in valid) {
  final deep = _parseToMinutes(entry['deepSleep']);
  final rem   = _parseToMinutes(entry['remSleep']);
  final light = _parseToMinutes(entry['lightSleep']);
  final awake = _parseToMinutes(entry['awakeTime']);
  final total = deep + rem + light + awake;

  totals.add(total);
  restTotals.add(deep + rem);
}

final avgTotal = totals.isEmpty ? 0.0 : totals.reduce((a, b) => a + b) / totals.length;
final avgRest  = restTotals.isEmpty ? 0.0 : restTotals.reduce((a, b) => a + b) / restTotals.length;


    // Compute maxY for chart padding
    final maxY = widget.buckets.fold<double>(0.0, (prev, entry) {
      final deep = _parseToMinutes(entry?['deepSleep']);
      final rem = _parseToMinutes(entry?['remSleep']);
      final light = _parseToMinutes(entry?['lightSleep']);
      final awake = _parseToMinutes(entry?['awakeTime']);
      final total = deep + rem + light + awake;
      return total > prev ? total : prev;
    }) + 40.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Sleep Stages',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ),

        // Chart + Legend
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartH = constraints.maxHeight * 0.65;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: chartH,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            builder: (context, anim, _) {
                              final animatedGroups = barGroups.map((grp) {
                                final rods = grp.barRods.map((rod) {
                                  final toY = rod.toY * anim;
                                  double start = 0.0;
                                  final stacks = rod.rodStackItems.map((item) {
                                    final from = item.fromY * anim;
                                    final toYSeg = item.toY * anim;
                                    start = toYSeg;
                                    return BarChartRodStackItem(from, toYSeg, item.color);
                                  }).toList();
                                  return BarChartRodData(
                                    toY: toY > 0 ? toY : 0.1,
                                    width: rod.width,
                                    borderRadius: rod.borderRadius,
                                    rodStackItems: stacks,
                                  );
                                }).toList();
                                return BarChartGroupData(x: grp.x, barRods: rods);
                              }).toList();

                              return BarChart(
                                BarChartData(
                                  maxY: maxY,
                                  barGroups: animatedGroups,
                                  alignment: BarChartAlignment.spaceAround,

                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 60.0,
                                        reservedSize: 40.0,
                                        getTitlesWidget: (value, _) {
                                          if (value % 60 != 0) return const SizedBox.shrink();
                                          return Text(
                                            '${(value / 60).round()}h',
                                            style: const TextStyle(fontSize: 10),
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
      if (idx < 0 || idx >= widget.days.length) return const SizedBox.shrink();
      if (idx % step != 0) return const SizedBox.shrink();
      return Text(
        DateFormat('M/d').format(widget.days[idx]),
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
                                    horizontalInterval: 60.0,
                                    getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white24, strokeWidth: 0.5),
                                    drawVerticalLine: false,
                                  ),

                                  extraLinesData: ExtraLinesData(
                                    horizontalLines: [
                                      HorizontalLine(
                                        y: avgRest,
                                        color: Colors.greenAccent.withOpacity(0.7),
                                        strokeWidth: 1,
                                        dashArray: [4, 4],
                                        label: HorizontalLineLabel(
                                          show: true,
                                          alignment: Alignment.topLeft,
                                          labelResolver: (_) => _formatDuration(avgRest),
                                          style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
                                        ),
                                      ),
                                      HorizontalLine(
                                        y: avgTotal,
                                        color: Colors.blueAccent.withOpacity(0.7),
                                        strokeWidth: 1,
                                        dashArray: [4, 4],
                                        label: HorizontalLineLabel(
                                          show: true,
                                          alignment: Alignment.topLeft,
                                          labelResolver: (_) => _formatDuration(avgTotal),
                                          style: const TextStyle(color: Colors.blueAccent, fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),

                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(getTooltipItem: (_,__,___,____) => null),
                                    touchCallback: (event, response) {
                                      final touchedSpot = response?.spot;
                                      if (!event.isInterestedForInteractions || touchedSpot == null || touchedSpot.touchedStackItem == null) {
                                        setState(() {
                                          touchedIndex = null;
                                          touchPosition = null;
                                          _touchedSegment = null;
                                        });
                                        return;
                                      }
                                      final idx = touchedSpot.touchedBarGroupIndex;
                                      final offset = touchedSpot.offset;
                                      final color = touchedSpot.touchedStackItem!.color;
                                      final segment = (color == const Color(0xFF80CBC4) || color == const Color(0xFFCE93D8)) ? 'dr' : 'la';
                                      setState(() {
                                        touchedIndex = idx;
                                        touchPosition = offset;
                                        _touchedSegment = segment;
                                      });
                                    },
                                  ),

                                  borderData: FlBorderData(show: false),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 8),

                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 6,
                          children: const [
                            _LegendItem(label: 'Deep', color: Color(0xFF80CBC4)),
                            _LegendItem(label: 'REM', color: Color(0xFFCE93D8)),
                            _LegendItem(label: 'Light', color: Color(0xFFFFF59D)),
                            _LegendItem(label: 'Awake', color: Color(0xFFE57373)),
                            _LegendLineItem(label: 'Avg Rest', color: Colors.greenAccent),
                            _LegendLineItem(label: 'Avg Total', color: Colors.blueAccent),
                          ],
                        ),
                      ],
                    ),

                    if (touchedIndex != null && touchPosition != null && _touchedSegment != null)
                      Positioned(
                        left: touchPosition!.dx - 60,
                        top: (touchPosition!.dy - chartH - 16).clamp(16.0, double.infinity),
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat.MMMd().format(widget.days[touchedIndex!]),
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                                const SizedBox(height: 4),
                                if (_touchedSegment == 'dr') ...[
                                  _buildTooltipRow('Deep', _formatDuration(_parseToMinutes(widget.buckets[touchedIndex!]?['deepSleep']))),
                                  _buildTooltipRow('REM', _formatDuration(_parseToMinutes(widget.buckets[touchedIndex!]?['remSleep']))),
                                ] else ...[
                                  _buildTooltipRow('Light', _formatDuration(_parseToMinutes(widget.buckets[touchedIndex!]?['lightSleep']))),
                                  _buildTooltipRow('Awake', _formatDuration(_parseToMinutes(widget.buckets[touchedIndex!]?['awakeTime']))),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Legend swatches unchanged
class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}

class _LegendLineItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendLineItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 16, height: 2, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}