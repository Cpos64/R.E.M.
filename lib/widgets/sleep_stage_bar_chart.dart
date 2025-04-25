import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SleepStageBarChart extends StatefulWidget {
  final List<Map<String, dynamic>> sleepData;

  const SleepStageBarChart({super.key, required this.sleepData});

  @override
  State<SleepStageBarChart> createState() => _SleepStageBarChartState();
}

class _SleepStageBarChartState extends State<SleepStageBarChart> {
  int? touchedIndex;
  Offset? touchPosition;

  double _parseToMinutes(dynamic duration) {
    if (duration == null) return 0.0;
    final durationStr = duration.toString();
    final hours = RegExp(r'(\d+)h').firstMatch(durationStr)?.group(1);
    final minutes = RegExp(r'(\d+)m').firstMatch(durationStr)?.group(1);
    return ((int.tryParse(hours ?? '0') ?? 0) * 60 + (int.tryParse(minutes ?? '0') ?? 0)).toDouble();
  }

  String _formatDuration(double minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h${m.round()}m' : '${m.round()}m';
  }

  String _buildTooltipText(int index) {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day - (6 - index));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final data = widget.sleepData.firstWhere(
      (e) => DateFormat('yyyy-MM-dd').format(e['date']) == dateStr,
      orElse: () => {},
    );

    final deep = _parseToMinutes(data?['deepSleep']);
    final rem = _parseToMinutes(data?['remSleep']);
    final light = _parseToMinutes(data?['lightSleep']);
    final awake = _parseToMinutes(data?['awakeTime']);
    final total = deep + rem + light + awake;

    return [
      if (deep > 0) '• Deep: ${_formatDuration(deep)}',
      if (rem > 0) '• REM: ${_formatDuration(rem)}',
      if (light > 0) '• Light: ${_formatDuration(light)}',
      if (awake > 0) '• Awake: ${_formatDuration(awake)}',
      'Total: ${_formatDuration(total)}'
    ].join('\n');
  }

  double _calculateMaxY() {
    double maxY = 0;
    for (var data in widget.sleepData) {
      final total = _parseToMinutes(data['deepSleep']) +
          _parseToMinutes(data['remSleep']) +
          _parseToMinutes(data['lightSleep']) +
          _parseToMinutes(data['awakeTime']);
      if (total > maxY) maxY = total;
    }
    return maxY + 40;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final List<DateTime> past7Days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - (6 - i)),
    );

    final Map<String, Map<String, dynamic>> dataByDate = {
      for (var entry in widget.sleepData)
        DateFormat('yyyy-MM-dd').format(entry['date'] as DateTime): entry
    };

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < past7Days.length; i++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(past7Days[i]);
      final data = dataByDate[dateStr];

      final deep = _parseToMinutes(data?['deepSleep']);
      final rem = _parseToMinutes(data?['remSleep']);
      final light = _parseToMinutes(data?['lightSleep']);
      final awake = _parseToMinutes(data?['awakeTime']);
      final total = deep + rem + light + awake;

      const double minVisible = 0.1;

      final barRods = BarChartRodData(
        toY: total > 0 ? total : minVisible,
        rodStackItems: [
          BarChartRodStackItem(0, deep > 0 ? deep : minVisible, const Color(0xFF80CBC4)),
          BarChartRodStackItem(deep, deep + (rem > 0 ? rem : minVisible), const Color(0xFFCE93D8)),
          BarChartRodStackItem(deep + rem, deep + rem + (light > 0 ? light : minVisible), const Color(0xFFFFF59D)),
          BarChartRodStackItem(deep + rem + light, total > 0 ? total : minVisible, const Color(0xFFE57373)),
        ],
        width: 18,
        borderRadius: BorderRadius.circular(2),
      );

      barGroups.add(BarChartGroupData(x: i, barRods: [barRods]));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxHeight * 0.65;
        final legendHeight = constraints.maxHeight * 0.15;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: chartHeight,
                    child: BarChart(
                      BarChartData(
                        maxY: _calculateMaxY(),
                        barGroups: barGroups,
                        alignment: BarChartAlignment.spaceAround,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 60,
                              reservedSize: 42,
                              getTitlesWidget: (value, _) {
                                final h = value ~/ 60;
                                final m = value % 60;
                                return Text(
                                  m == 0 ? '${h}h' : '${h}h${m}m',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                int i = value.toInt();
                                if (i < 0 || i >= past7Days.length) return const SizedBox();
                                return Text(
                                  DateFormat('E').format(past7Days[i]),
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
                          horizontalInterval: 60,
                          getDrawingHorizontalLine: (_) => FlLine(color: Colors.white24, strokeWidth: 0.5),
                        ),
                        borderData: FlBorderData(show: false),
barTouchData: BarTouchData(
  enabled: true,
  touchCallback: (event, response) {
    if (!event.isInterestedForInteractions || response == null || response.spot == null) {
      setState(() {
        touchedIndex = null;
        touchPosition = null;
      });
      return;
    }

    final spot = response.spot!;
    setState(() {
      touchedIndex = spot.touchedBarGroupIndex;
      touchPosition = spot.offset;
    });
  },
  touchTooltipData: BarTouchTooltipData(
    getTooltipItem: (_, __, ___, ____) => null, // 👈 disables the default tooltip
  ),
),

                      ),
                    ),
                  ),
                  SizedBox(
                    height: legendHeight,
                    child: Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 6,
                        children: const [
                          _LegendItem(label: 'Deep', color: Color(0xFF80CBC4)),
                          _LegendItem(label: 'REM', color: Color(0xFFCE93D8)),
                          _LegendItem(label: 'Light', color: Color(0xFFFFF59D)),
                          _LegendItem(label: 'Awake', color: Color(0xFFE57373)),
                        ],
                      ),
                    ),
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
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
