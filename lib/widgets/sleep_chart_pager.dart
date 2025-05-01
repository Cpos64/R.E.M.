import 'package:flutter/material.dart';
import 'sleep_score_chart.dart';
import 'sleep_stage_bar_chart.dart';
import 'sleep_consistency_stream.dart';

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
    return Column(
      children: [
        // ── PageView that sizes itself for Charts 1 & 2, but fixes height only for Chart 3 ──
        Expanded(
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              // Chart #1: Sleep Score
              SleepScoreChart(sleepData: widget.sleepData),

              // Chart #2: Sleep Stages
              SleepStageBarChart(sleepData: widget.sleepData),

              // Chart #3: Sleep Consistency (boxed to 380px so it can't overflow)
              SizedBox(
                height: 380,
                child: const SleepConsistencyStream(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        // ── Pager controls ──
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
