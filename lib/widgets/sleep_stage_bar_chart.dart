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

  String _buildTooltipText(int index) {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day - (6 - index));
    final key = DateFormat('yyyy-MM-dd').format(date);
    final entry = widget.sleepData.firstWhere(
      (e) => DateFormat('yyyy-MM-dd').format(e['date'] as DateTime) == key,
      orElse: () => <String, dynamic>{},
    );

    final deep  = _parseToMinutes(entry['deepSleep']);
    final rem   = _parseToMinutes(entry['remSleep']);
    final light = _parseToMinutes(entry['lightSleep']);
    final awake = _parseToMinutes(entry['awakeTime']);
    final total = deep + rem + light + awake;

    return [
      if (deep  > 0) '• Deep:  ${_formatDuration(deep)}',
      if (rem   > 0) '• REM:   ${_formatDuration(rem)}',
      if (light > 0) '• Light: ${_formatDuration(light)}',
      if (awake > 0) '• Awake: ${_formatDuration(awake)}',
      'Total: ${_formatDuration(total)}',
    ].join('\n');
  }

  double _calculateMaxY() {
    double maxY = 0.0;
    for (var e in widget.sleepData) {
      final total = _parseToMinutes(e['deepSleep']) +
                    _parseToMinutes(e['remSleep']) +
                    _parseToMinutes(e['lightSleep']) +
                    _parseToMinutes(e['awakeTime']);
      if (total > maxY) maxY = total;
    }
    return maxY + 40.0;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final past7Days = List<DateTime>.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - (6 - i)),
    );

    // Build barGroups same as before
    final dataByDate = {
      for (var e in widget.sleepData)
        DateFormat('yyyy-MM-dd').format(e['date'] as DateTime): e
    };
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < past7Days.length; i++) {
      final key   = DateFormat('yyyy-MM-dd').format(past7Days[i]);
      final entry = dataByDate[key] ?? {};
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
              BarChartRodStackItem(0, deep  > 0 ? deep  : minVis, const Color(0xFF80CBC4)),
              BarChartRodStackItem(deep, deep + (rem   > 0 ? rem   : minVis), const Color(0xFFCE93D8)),
              BarChartRodStackItem(deep + rem, deep + rem + (light > 0 ? light : minVis), const Color(0xFFFFF59D)),
              BarChartRodStackItem(deep + rem + light, total > 0 ? total : minVis, const Color(0xFFE57373)),
            ],
          )
        ],
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Title ────────────────────────────────────────────────────────────────
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

        // ─── Chart & Legend ────────────────────────────────────────────────────────
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
                        SizedBox(
                          height: chartH,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeInOut,
                            builder: (context, anim, _) {
                              // Animate bar heights
                              final animatedGroups = barGroups.map((grp) {
                                final rods = grp.barRods.map((rod) {
                                  final toY = rod.toY * anim;
                                  double start = 0.0;
                                  final stacks = rod.rodStackItems.map((item) {
                                    final from = item.fromY * anim;
                                    final to   = item.toY * anim;
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
                                    topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    horizontalInterval: 60.0,
                                    getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white24, strokeWidth: 0.5),
                                    drawVerticalLine: false,
                                  ),
barTouchData: BarTouchData(
  enabled: true,
  touchTooltipData: BarTouchTooltipData(
    // 1) keep it fully inside the chart bounds
    fitInsideHorizontally: true,
    fitInsideVertically:   true,

    // 2) add breathing room
    tooltipPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    tooltipMargin: 4,

    // 3) two‐column, date + D/R / L/A rows
    getTooltipItem: (group, groupIndex, rod, rodIndex) {
      final idx = group.x.toInt();
      final date = past7Days[idx];
      final key  = DateFormat('yyyy-MM-dd').format(date);
      final entry = dataByDate[key] ?? {};

      final deep  = _parseToMinutes(entry['deepSleep']);
      final rem   = _parseToMinutes(entry['remSleep']);
      final light = _parseToMinutes(entry['lightSleep']);
      final awake = _parseToMinutes(entry['awakeTime']);

      final left1  = 'D:${_formatDuration(deep)}';
      final right1 = 'R:${_formatDuration(rem)}';
      final left2  = 'L:${_formatDuration(light)}';
      final right2 = 'A:${_formatDuration(awake)}';

      return BarTooltipItem(
        '',
        const TextStyle(), // we’ll use spans only
        children: [
          // Date header
          TextSpan(
            text: '${DateFormat.MMMd().format(date)}\n',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          // Deep / REM row
          TextSpan(
            text: '$left1   $right1\n',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          // Light / Awake row
          TextSpan(
            text: '$left2   $right2',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      );
    },
  ),
),

                                  borderData: FlBorderData(show: false),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: legendH),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 6,
                          children: const [
                            _LegendItem(label: 'Deep',  color: Color(0xFF80CBC4)),
                            _LegendItem(label: 'REM',   color: Color(0xFFCE93D8)),
                            _LegendItem(label: 'Light', color: Color(0xFFFFF59D)),
                            _LegendItem(label: 'Awake', color: Color(0xFFE57373)),
                          ],
                        ),
                      ],
                    ),
                    if (touchedIndex != null && touchPosition != null)
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
                            child: Text(
                              _buildTooltipText(touchedIndex!),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
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

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12.0, height: 12.0, color: color),
        const SizedBox(width: 4.0),
        Text(label, style: const TextStyle(fontSize: 12.0)),
      ],
    );
  }
}
