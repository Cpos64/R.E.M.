import 'package:flutter/material.dart';
import 'sleep_score_chart.dart';
import 'sleep_stage_bar_chart.dart';

class SleepChartPager extends StatefulWidget {
  final List<Map<String, dynamic>> sleepData;

  const SleepChartPager({super.key, required this.sleepData});

  @override
  State<SleepChartPager> createState() => _SleepChartPagerState();
}

class _SleepChartPagerState extends State<SleepChartPager> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  void _goToPage(int index) {
    if (index >= 0 && index <= 1) {
      _controller.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 420,
          child: PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              SleepScoreChart(sleepData: widget.sleepData),
              SleepStageBarChart(sleepData: widget.sleepData),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
            ),
            const SizedBox(width: 8),
            Text('Chart ${_currentPage + 1} of 2'),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _currentPage < 1 ? () => _goToPage(_currentPage + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}
