// lib/widgets/dream_chart_pager.dart

import 'package:flutter/material.dart';
import 'dream_count_line_chart.dart';

class DreamChartPager extends StatefulWidget {
  final List<Map<String, dynamic>> buckets;
  // NOTE: we no longer need an incoming `days` list here
  const DreamChartPager({
    Key? key,
    required this.buckets,
  }) : super(key: key);

  @override
  _DreamChartPagerState createState() => _DreamChartPagerState();
}

class _DreamChartPagerState extends State<DreamChartPager> {
  int _windowDays = 7;

  /// 1) Generate exactly `_windowDays` consecutive calendar days (no gaps).
  List<DateTime> get _filteredDays {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: _windowDays - 1));
    return List.generate(_windowDays, (i) => start.add(Duration(days: i)));
  }

  /// 2) Build one bucket per day, filling zeros for missing entries.
  List<Map<String, dynamic>> get _alignedBuckets {
    // build a lookup from date → count
    final map = <DateTime, int>{
      for (var b in widget.buckets)
        (b['date'] as DateTime): (b['totalCount'] as int)
    };
    return _filteredDays.map((day) {
      return {
        'date': day,
        'totalCount': map[day] ?? 0,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final days = _filteredDays;
    final buckets = _alignedBuckets;

    return Column(
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Dreams per Day',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),

        // Chart
        Expanded(
          child: DreamCountLineChart(
            key: ValueKey(days.length),  // forces a rebuild/animation when window size changes
            days: days,
            buckets: buckets,
          ),
        ),

        // Toggle buttons
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ToggleButtons(
            isSelected: [
              _windowDays == 7,
              _windowDays == 28,
              _windowDays == 90,
              _windowDays == 365,
            ],
            onPressed: (i) {
              setState(() {
                switch (i) {
                  case 0:
                    _windowDays = 7;
                    break;
                  case 1:
                    _windowDays = 28;
                    break;
                  case 2:
                    _windowDays = 90;
                    break;
                  default:
                    _windowDays = 365;
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('7 d')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('4 w')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('3 m')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('1 y')),
            ],
          ),
        ),
      ],
    );
  }
}
