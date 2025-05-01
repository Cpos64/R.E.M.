import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SleepStageBarChart extends StatefulWidget {
  final List<Map<String, dynamic>> sleepData;
  const SleepStageBarChart({Key? key, required this.sleepData}) : super(key: key);

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

  // Helper to fetch the entry map for a given bar index
  Map<String, dynamic> _entryAt(int index, List<DateTime> days, Map<String, Map<String, dynamic>> dataByDate) {
    final key = DateFormat('yyyy-MM-dd').format(days[index]);
    return dataByDate[key] ?? <String, dynamic>{};
  }

    /// Find the largest total-sleep value + 40 for padding.
  double _calculateMaxY() {
    double maxY = 0.0;
    for (var e in widget.sleepData) {
      final total = _parseToMinutes(e['deepSleep'])
                  + _parseToMinutes(e['remSleep'])
                  + _parseToMinutes(e['lightSleep'])
                  + _parseToMinutes(e['awakeTime']);
      if (total > maxY) maxY = total;
    }
    return maxY + 40.0;
  }

  /// Builds a Text row with a bold key and its formatted value.
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
    final now = DateTime.now();
    final past7Days = List<DateTime>.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - (6 - i)),
    );

    // Map date → record
    final dataByDate = {
      for (var e in widget.sleepData)
        DateFormat('yyyy-MM-dd').format(e['date'] as DateTime): e
    };

    // Build barGroups
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < past7Days.length; i++) {
      final entry = _entryAt(i, past7Days, dataByDate);
      final deep  = _parseToMinutes(entry['deepSleep']);
      final rem   = _parseToMinutes(entry['remSleep']);
      final light = _parseToMinutes(entry['lightSleep']);
      final awake = _parseToMinutes(entry['awakeTime']);
      final total = deep + rem + light + awake;
      const minVis = 0.1;

      barGroups.add(BarChartGroupData(
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
      ));
    }

    final totals = <double>[];
final restTotals = <double>[]; // deep + rem

for (int i = 0; i < past7Days.length; i++) {
  final entry  = _entryAt(i, past7Days, dataByDate);
  final deep   = _parseToMinutes(entry['deepSleep']);
  final rem    = _parseToMinutes(entry['remSleep']);
  final light  = _parseToMinutes(entry['lightSleep']);
  final awake  = _parseToMinutes(entry['awakeTime']);
  final total  = deep + rem + light + awake;
  totals.add(total);
  restTotals.add(deep + rem);
}

// overall averages
final avgTotal = totals.isEmpty ? 0.0 : totals.reduce((a, b) => a + b) / totals.length;
final avgRest  = restTotals.isEmpty ? 0.0 : restTotals.reduce((a, b) => a + b) / restTotals.length;

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
              final chartH  = constraints.maxHeight * 0.65;
              final legendH = constraints.maxHeight * 0.15;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Animated BarChart
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
                                    final to   = item.toY   * anim;
                                    final seg  = BarChartRodStackItem(from, to, item.color);
                                    start = to;
                                    return seg;
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
                                  maxY: _calculateMaxY(),
                                  barGroups: animatedGroups,
                                  alignment: BarChartAlignment.spaceAround,

                                  // Titles
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 60.0,
                                        reservedSize: 40.0,
                                        getTitlesWidget: (value, _) {
                                          if (value % 60 != 0) return const SizedBox.shrink();
                                          final h = (value / 60).round();
                                          return Text('${h}h', style: const TextStyle(fontSize: 10));
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, _) {
                                          final idx = value.toInt();
                                          if (idx < 0 || idx >= past7Days.length) return const SizedBox.shrink();
                                          return Text(
                                            DateFormat('E').format(past7Days[idx]),
                                            style: const TextStyle(fontSize: 10),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),

                                  // Grid
                                  gridData: FlGridData(
                                    show: true,
                                    horizontalInterval: 60.0,
                                    getDrawingHorizontalLine: (_) =>
                                        const FlLine(color: Colors.white24, strokeWidth: 0.5),
                                    drawVerticalLine: false,
                                  ),

extraLinesData: ExtraLinesData(
  horizontalLines: [
    // Average restorative sleep (deep+REM)
    HorizontalLine(
      y: avgRest,
      color: Colors.greenAccent.withOpacity(0.7),
      strokeWidth: 1,
      dashArray: [4, 4],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topLeft,               // ← move to left
        labelResolver: (_) => _formatDuration(avgRest),// ← only “1h59m”
        style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
      ),
    ),
    // Average total sleep
    HorizontalLine(
      y: avgTotal,
      color: Colors.blueAccent.withOpacity(0.7),
      strokeWidth: 1,
      dashArray: [4, 4],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.bottomLeft,               // ← move to left
        labelResolver: (_) => _formatDuration(avgTotal),// ← only “7h30m”
        style: const TextStyle(color: Colors.blueAccent, fontSize: 10),
      ),
    ),
  ],
),



barTouchData: BarTouchData(
  enabled: true,
  touchTooltipData: BarTouchTooltipData(getTooltipItem: (_,__,___,____) => null),
  touchCallback: (event, response) {
    // grab the tapped stack‐item (if any)
    final touchedSpot = response?.spot;
    if (!event.isInterestedForInteractions ||
        touchedSpot == null ||
        touchedSpot.touchedStackItem == null) {
      setState(() {
        touchedIndex    = null;
        touchPosition   = null;
        _touchedSegment = null;
      });
      return;
    }

    // now it’s safe to read from touchedSpot
    final idx     = touchedSpot.touchedBarGroupIndex;
    final offset  = touchedSpot.offset;
    final color   = touchedSpot.touchedStackItem!.color;
    final segment = (color == const Color(0xFF80CBC4) ||
                     color == const Color(0xFFCE93D8))
        ? 'dr'
        : 'la';

    setState(() {
      touchedIndex    = idx;
      touchPosition   = offset;
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

                        // Legend
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 6,
                          children: const [
                            _LegendItem(label: 'Deep',  color: Color(0xFF80CBC4)),
                            _LegendItem(label: 'REM',   color: Color(0xFFCE93D8)),
                            _LegendItem(label: 'Light', color: Color(0xFFFFF59D)),
                            _LegendItem(label: 'Awake', color: Color(0xFFE57373)),
                            _LegendLineItem(label: 'Avg Rest',  color: Colors.greenAccent), // ← new
                            _LegendLineItem(label: 'Avg Total', color: Colors.blueAccent),  // ← new
                          ],
                        ),
                      ],
                    ),
// Manual overlay tooltip
if (touchedIndex != null && touchPosition != null && _touchedSegment != null)
  Positioned(
    left: touchPosition!.dx - 60,
    top: (touchPosition!.dy - 140).clamp(16.0, double.infinity),
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
            // Always show date at top
            Text(
              DateFormat.MMMd().format(past7Days[touchedIndex!]),
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            const SizedBox(height: 4),
            // Show rows based on which segment was touched
            if (_touchedSegment == 'dr') ...[
              _buildTooltipRow('Deep', _formatDuration(_parseToMinutes(_entryAt(touchedIndex!, past7Days, dataByDate)['deepSleep']))),
              _buildTooltipRow('REM',  _formatDuration(_parseToMinutes(_entryAt(touchedIndex!, past7Days, dataByDate)['remSleep']))),
            ] else ...[
              _buildTooltipRow('Light', _formatDuration(_parseToMinutes(_entryAt(touchedIndex!, past7Days, dataByDate)['lightSleep']))),
              _buildTooltipRow('Awake', _formatDuration(_parseToMinutes(_entryAt(touchedIndex!, past7Days, dataByDate)['awakeTime']))),
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

/// Square swatch + label for the four sleep stages
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

/// Tiny line swatch + label for our average‐lines
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
