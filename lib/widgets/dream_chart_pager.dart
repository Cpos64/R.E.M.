// lib/widgets/dream_chart_pager.dart

import 'package:flutter/material.dart';
import 'dream_count_line_chart.dart';

class DreamChartPager extends StatefulWidget {
  final List<Map<String, dynamic>> buckets;
  final List<DateTime> days;

  const DreamChartPager({
    Key? key,
    required this.buckets,
    required this.days,
  }) : super(key: key);

  @override
  _DreamChartPagerState createState() => _DreamChartPagerState();
}

class _DreamChartPagerState extends State<DreamChartPager> {
  int _windowDays = 7;

  /// Returns only the last `_windowDays` worth of buckets+days
  List<DateTime> get _filteredDays {
    final cutoff = DateTime.now().subtract(Duration(days: _windowDays - 1));
    return widget.days.where((d) => !d.isBefore(cutoff)).toList();
  }

  List<Map<String, dynamic>> get _filteredBuckets {
    final validDays = _filteredDays.toSet();
    return widget.buckets.where((b) {
      final d = b['date'] as DateTime;
      return validDays.contains(d);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
            buckets: _filteredBuckets,
            days: _filteredDays,
          ),
        ),

        // Toggle buttons for window size
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ToggleButtons(
            isSelected: [
              _windowDays == 7,
              _windowDays == 30,
              _windowDays == 90,
            ],
            onPressed: (i) {
              setState(() {
                _windowDays = (i == 0 ? 7 : i == 1 ? 30 : 90);
              });
            },
            borderRadius: BorderRadius.circular(8),
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('7 d')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('30 d')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('90 d')),
            ],
          ),
        ),
      ],
    );
  }
}
