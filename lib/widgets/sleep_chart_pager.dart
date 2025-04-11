import 'package:flutter/material.dart';
import 'sleep_line_chart.dart';

class SleepChartPager extends StatefulWidget {
  final List<Map<String, dynamic>> sleepData;

  const SleepChartPager({super.key, required this.sleepData});

  @override
  State<SleepChartPager> createState() => _SleepChartPagerState();
}

class _SleepChartPagerState extends State<SleepChartPager> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  void _goToPage(int page) {
    _controller.animateToPage(
      page,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              SleepLineChart(
                sleepData: widget.sleepData,
                showOnlyTotal: true,
              ),
              SleepLineChart(
                sleepData: widget.sleepData,
                showOnlyTotal: false,
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
              icon: Icon(Icons.arrow_back),
            ),
            Text(
              _currentPage == 0 ? 'Total Sleep' : 'Deep / REM / Awake',
              style: TextStyle(fontSize: 14),
            ),
            IconButton(
              onPressed: _currentPage < 1 ? () => _goToPage(1) : null,
              icon: Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ],
    );
  }
}
