import 'package:flutter/material.dart';
import 'sleep_score_chart.dart';
import 'sleep_stage_bar_chart.dart';
import 'sleep_consistency_chart.dart';

class SleepChartPager extends StatefulWidget {
  final List<Map<String, dynamic>> sleepData;
  final int selectedWindow;
  final ValueChanged<int> onWindowChanged;

  const SleepChartPager({
    Key? key,
    required this.sleepData,
    required this.selectedWindow,
    required this.onWindowChanged,
  }) : super(key: key);

  @override
  State<SleepChartPager> createState() => _SleepChartPagerState();
}

class _SleepChartPagerState extends State<SleepChartPager> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  void _goToPage(int index) {
    if (index >= 0 && index < 3) {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1️⃣ Determine date range:
    final today = DateTime.now();
    final windowStart = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: widget.selectedWindow - 1));

    // 2️⃣ Build N days in that range:
    final days = List<DateTime>.generate(
      widget.selectedWindow,
      (i) => windowStart.add(Duration(days: i)),
    );

    // 3️⃣ Filter your incoming data to that window:
    final filtered = widget.sleepData.where((entry) {
      final raw = entry['date'];
      final entryDate = raw is DateTime
          ? raw
          : DateTime.parse(raw as String).toLocal();
      return !entryDate.isBefore(windowStart) && !entryDate.isAfter(today);
    }).toList();

    // 4️⃣ Build exactly N buckets (null = missing day)
    final buckets = List<Map<String, dynamic>?>.generate(
      widget.selectedWindow,
      (i) {
        final day = days[i];
        // look for an entry on that day:
        for (var entry in filtered) {
          final raw = entry['date'];
          final d = raw is DateTime
              ? raw
              : DateTime.parse(raw as String);
          if (d.year == day.year &&
              d.month == day.month &&
              d.day == day.day) {
            return entry;
          }
        }
        // none found → keep the slot empty
        return null;
      },
    );

    return Column(
      children: [
        // ── The three charts in a PageView ──
        Expanded(
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              SleepScoreChart(buckets: buckets, days: days),
              SleepStageBarChart(buckets: buckets, days: days),
              SizedBox(
                height: 380,
                child: SleepConsistencyChart(buckets: buckets, days: days),
              ),
            ],
          ),
        ),

        // ── Toggle for 7d/4w/3m/1y *below* the charts ──
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [7, 28, 90, 365].map((value) {
              final isSelected = value == widget.selectedWindow;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(value == 7
                      ? '7 d'
                      : value == 28
                          ? '4 w'
                          : value == 90
                              ? '3 m'
                              : '1 y'),
                  selected: isSelected,
                  onSelected: (_) => widget.onWindowChanged(value),
                ),
              );
            }).toList(),
          ),
        ),

        // ── “Chart X of 3” pager controls ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _currentPage > 0
                  ? () => _goToPage(_currentPage - 1)
                  : null,
            ),
            const SizedBox(width: 8),
            Text('Chart ${_currentPage + 1} of 3'),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _currentPage < 2
                  ? () => _goToPage(_currentPage + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
