import 'package:flutter/material.dart';

class DreamChartPager extends StatefulWidget {
  final List<Widget> charts;
  const DreamChartPager({ Key? key, required this.charts }) : super(key: key);

  @override
  _DreamChartPagerState createState() => _DreamChartPagerState();
}

class _DreamChartPagerState extends State<DreamChartPager> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1) Force the PageView to fill available height
        Expanded(
          child: PageView(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _current = i),
            children: widget.charts,
          ),
        ),

        // 2) Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.charts.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              width: _current == i ? 10.0 : 8.0,
              height: _current == i ? 10.0 : 8.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _current
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
              ),
            );
          }),
        ),
      ],
    );
  }
}
