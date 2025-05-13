// lib/widgets/dream_sentiment_line_chart.dart

import 'package:flutter/material.dart';

/// Shows how your dream‐sentiment scores drift over time.
/// (~> later you’ll replace the Container with an FL_Chart LineChart)
class DreamSentimentLineChart extends StatelessWidget {
  const DreamSentimentLineChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        'Sentiment Over Time',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
