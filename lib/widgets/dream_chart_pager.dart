// lib/widgets/dream_chart_pager.dart

import 'package:flutter/material.dart';
import 'dream_count_line_chart.dart';
import 'dream_genre_trends_chart.dart';
import 'dream_recall_word_chart.dart';

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
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  int _windowDays = 7;

  // chart titles in order
  static const _titles = [
    'Dreams per Day',
    'Genre Trends',
    'Recall vs. Word Count',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
    if (_filteredDays.isEmpty) {
      return const Center(
        child: Text('No dream data for this range'),
      );
    }

    return Column(
      children: [
        // 1) Title
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _titles[_pageIndex],
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),

        // 2) The PageView itself
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _pageIndex = idx),
            children: [
              // pass in filtered data for the chosen window
              DreamCountLineChart(
                buckets: _filteredBuckets,
                days: _filteredDays,
              ),
              DreamGenreTrendsChart(
                buckets: _filteredBuckets,
                days: _filteredDays,
              ),
              DreamRecallWordChart(
                buckets: _filteredBuckets,
              ),
            ],
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


        // 4) Page indicator with arrows
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // back arrow
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _pageIndex > 0
                    ? () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                    : null,
              ),

              // text indicator
              Text(
                'Chart ${_pageIndex + 1} of ${_titles.length}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              // forward arrow
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _pageIndex < _titles.length - 1
                    ? () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
