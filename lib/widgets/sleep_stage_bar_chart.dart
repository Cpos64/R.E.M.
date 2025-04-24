import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SleepStageBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> sleepData;

  const SleepStageBarChart({super.key, required this.sleepData});

  double _parseToMinutes(dynamic duration) {
    if (duration == null) return 0.0;
    final durationStr = duration.toString();

    final hours = RegExp(r'(\d+)h').firstMatch(durationStr)?.group(1);
    final minutes = RegExp(r'(\d+)m').firstMatch(durationStr)?.group(1);

    return ((int.tryParse(hours ?? '0') ?? 0) * 60 +
            (int.tryParse(minutes ?? '0') ?? 0))
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final List<DateTime> past7Days = List.generate(7, (i) => DateTime(now.year, now.month, now.day - (6 - i)));

    final Map<String, Map<String, dynamic>> dataByDate = {
      for (var entry in sleepData)
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

      final barRods = BarChartRodData(
        toY: deep + rem + light + awake,
        rodStackItems: [
          if (deep > 0) BarChartRodStackItem(0, deep, const Color(0xFF80CBC4)),
          if (rem > 0) BarChartRodStackItem(deep, deep + rem, const Color(0xFFCE93D8)),
          if (light > 0) BarChartRodStackItem(deep + rem, deep + rem + light, const Color(0xFFFFF59D)),
          if (awake > 0) BarChartRodStackItem(deep + rem + light, deep + rem + light + awake, const Color(0xFFE57373)),
        ],
        width: 18,
        borderRadius: BorderRadius.circular(2),
      );

      barGroups.add(
        BarChartGroupData(x: i, barRods: [barRods]),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 24.0),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: BarChart(
                BarChartData(
                  maxY: _calculateMaxY(),
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 60,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) {
                          final hours = value ~/ 60;
                          final minutes = value % 60;
                          return Text(
                            minutes == 0 ? '${hours}h' : '${hours}h${minutes}m',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          int index = value.toInt();
                          if (index < 0 || index >= past7Days.length) return const SizedBox();
                          return Text(
                            DateFormat('E').format(past7Days[index]),
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
                    drawHorizontalLine: true,
                    horizontalInterval: 60,
                    getDrawingHorizontalLine: (_) => FlLine(color: Colors.white24, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: true),
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(y: 480, color: Colors.white24, strokeWidth: 0.5),
                  ]),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final index = group.x.toInt();
                        final dateStr = DateFormat('yyyy-MM-dd').format(past7Days[index]);
                        final data = dataByDate[dateStr];

                        final deep = _parseToMinutes(data?['deepSleep']);
                        final rem = _parseToMinutes(data?['remSleep']);
                        final light = _parseToMinutes(data?['lightSleep']);
                        final awake = _parseToMinutes(data?['awakeTime']);
                        final total = deep + rem + light + awake;

                        if (total == 0) return null;

                        return BarTooltipItem(
                          [
                            if (deep > 0) 'Deep: ${_formatDuration(deep)}\n',
                            if (rem > 0) 'REM: ${_formatDuration(rem)}\n',
                            if (light > 0) 'Light: ${_formatDuration(light)}\n',
                            if (awake > 0) 'Awake: ${_formatDuration(awake)}\n',
                            '\nTotal: ${_formatDuration(total)}',
                          ].join(),
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
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
        ],
      ),
    );
  }

  double _calculateMaxY() {
    double maxY = 0;
    for (var data in sleepData) {
      final total = _parseToMinutes(data['deepSleep']) +
          _parseToMinutes(data['remSleep']) +
          _parseToMinutes(data['lightSleep']) +
          _parseToMinutes(data['awakeTime']);
      if (total > maxY) maxY = total;
    }
    return maxY + 40;
  }

  String _formatDuration(double minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h${m.round()}m' : '${m.round()}m';
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
