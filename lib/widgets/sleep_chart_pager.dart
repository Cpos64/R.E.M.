import 'package:flutter/material.dart';
import 'sleep_score_chart.dart';
import 'sleep_stage_bar_chart.dart';
import 'sleep_consistency_chart.dart'; // ← updated import

class SleepChartPager extends StatefulWidget {
  final List<Map<String, dynamic>> sleepData;

  const SleepChartPager({
    Key? key,
    required this.sleepData,
  }) : super(key: key);

  @override
  State<SleepChartPager> createState() => _SleepChartPagerState();
}

class _SleepChartPagerState extends State<SleepChartPager> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  int _selectedWindow = 7;

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
    // 1️⃣ Determine date range
    final today = DateTime.now();
    final windowStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: _selectedWindow - 1));

    // 2️⃣ Build list of consecutive days
    final days = List<DateTime>.generate(
      _selectedWindow,
      (i) => windowStart.add(Duration(days: i)),
    );

    // 3️⃣ Filter raw data into the window
    final filtered = widget.sleepData.where((entry) {
      final dateVal = entry['date'];
      DateTime entryDate;
      if (dateVal is DateTime) {
        entryDate = dateVal;
      } else if (dateVal is String) {
        entryDate = DateTime.tryParse(dateVal)!.toLocal();
      } else {
        return false;
      }
      return !entryDate.isBefore(windowStart) && !entryDate.isAfter(today);
    }).toList();

    // 4️⃣ Build exactly N buckets (null for missing days)
    final buckets = List<Map<String, dynamic>?>.generate(
      _selectedWindow,
      (i) {
        final day = days[i];
        for (var entry in filtered) {
          final dv = entry['date'];
          DateTime d;
          if (dv is DateTime) {
            d = dv;
          } else {
            d = DateTime.parse(dv as String);
          }
          if (d.year == day.year && d.month == day.month && d.day == day.day) {
            return entry;
          }
        }
        return null;
      },
    );

    return Column(
      children: [
        // ── Charts ──
        Expanded(
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              SleepScoreChart(buckets: buckets, days: days),
              SleepStageBarChart(buckets: buckets, days: days),
              // ← now instantiating the updated chart directly:
              SizedBox(
                height: 380,
                child: SleepConsistencyChart(buckets: buckets, days: days),
              ),
            ],
          ),
        ),

        // ── Time-window toggles ──
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [7, 30, 90].map((value) {
              final isSelected = value == _selectedWindow;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text('$value d'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedWindow = value),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // ── Pager controls ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed:
                  _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
            ),
            const SizedBox(width: 8),
            Text('Chart ${_currentPage + 1} of 3'),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed:
                  _currentPage < 2 ? () => _goToPage(_currentPage + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}
