import 'package:flutter_test/flutter_test.dart';
import 'package:rem/firestore_service.dart';
import 'package:rem/widgets/sleep_chart_pager.dart';
import 'package:intl/intl.dart';

void main() {
  test('circularDiffMinutes handles midnight wrap', () {
    final a = DateTime(2024, 1, 1, 23, 45);
    final b = DateTime(2024, 1, 2, 0, 15);
    expect(circularDiffMinutes(a, b), 30);
  });

  test('circularDiffMinutes basic difference', () {
    final a = DateTime(2024, 1, 1, 10, 0);
    final b = DateTime(2024, 1, 1, 11, 30);
    expect(circularDiffMinutes(a, b), 90);
  });

  test('circular mean around midnight in SleepChartPager', () {
    final today = DateTime.now();
    final data = [
      {
        'date': today,
        'sleepScore': 0,
        'totalDuration': '0h0m',
        'deepSleep': '0h0m',
        'remSleep': '0h0m',
        'lightSleep': '0h0m',
        'awakeTime': '0h0m',
        'timeInBed': '11:00 PM',
        'timeAsleep': '11:30 PM',
        'timeAwake': '7:00 AM',
      },
      {
        'date': today,
        'sleepScore': 0,
        'totalDuration': '0h0m',
        'deepSleep': '0h0m',
        'remSleep': '0h0m',
        'lightSleep': '0h0m',
        'awakeTime': '0h0m',
        'timeInBed': '1:00 AM',
        'timeAsleep': '1:30 AM',
        'timeAwake': '9:00 AM',
      },
    ];

    final pager = SleepChartPager(
      sleepData: data,
      selectedWindow: 7,
      onWindowChanged: (_) {},
    );
    final state = pager.createState();
    final result = (state as dynamic)
        ._buildAggregated(data, today.subtract(const Duration(days: 6)), 7);
    final buckets = result['buckets'] as List<dynamic>;
    final bucket = buckets.first as Map<String, dynamic>;

    final expected = DateFormat.jm().format(DateTime(0, 0, 0, 0, 0));
    expect(bucket['timeInBed'], expected);
  });
}
