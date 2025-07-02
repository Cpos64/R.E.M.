import 'package:flutter/material.dart';
import 'sleep_score_chart.dart';
import 'sleep_stage_bar_chart.dart';
import 'sleep_consistency_chart.dart';
import 'package:intl/intl.dart';

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

  double _parseToMinutes(dynamic duration) {
    if (duration == null) return 0.0;
    final s = duration.toString();
    final h = int.tryParse(RegExp(r'(\d+)h').firstMatch(s)?.group(1) ?? '') ?? 0;
    final m = int.tryParse(RegExp(r'(\d+)m').firstMatch(s)?.group(1) ?? '') ?? 0;
    return (h * 60 + m).toDouble();
  }

  int _bucketSizeForWindow(int window) {
    if (window == 90) return 7; // 3M → weekly buckets
    // 1Y uses monthly buckets handled separately
    return 1;
  }

  DateTime? _parseTimeObj(String? text) {
    if (text == null || text.isEmpty) return null;
    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;
    try {
      return DateFormat.jm().parse(text);
    } catch (_) {
      return null;
    }
  }

  int _toMinutes(DateTime? dt) => dt == null ? 0 : dt.hour * 60 + dt.minute;

  String _fmtDuration(double minutes) {
    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    return '${h}h${m}m';
  }

  String _fmtTime(double value) {
    final h = value.floor();
    final m = ((value - h) * 60).round();
    return DateFormat.jm().format(DateTime(0, 0, 0, h, m));
  }

  Map<String, List<dynamic>> _buildAggregated(
      List<Map<String, dynamic>> data, DateTime _, int window) {
    if (window == 365) {
      // Build 12 buckets based on calendar months
      final today = DateTime.now();
      var monthStart = DateTime(today.year, today.month, 1);

      final days = <DateTime>[];
      final buckets = <Map<String, dynamic>?>[];

      for (var i = 0; i < 12; i++) {
        final nextMonth = DateTime(monthStart.year, monthStart.month + 1, 1);
        final monthEnd = nextMonth.subtract(const Duration(days: 1));
        days.insert(0, monthEnd);

        final entries = data.where((e) {
          final raw = e['date'];
          final dt = raw is DateTime
              ? raw
              : DateTime.parse(raw as String).toLocal();
          return !dt.isBefore(monthStart) && dt.isBefore(nextMonth);
        }).toList();

        if (entries.isEmpty) {
          buckets.add(null);
        } else {
          final len = entries.length;
          double sumScore = 0,
              sumTotal = 0,
              sumDeep = 0,
              sumRem = 0,
              sumLight = 0,
              sumAwake = 0,
              sumBed = 0,
              sumAsleep = 0,
              sumWake = 0;

          for (var e in entries) {
            sumScore += (e['sleepScore'] as num?)?.toDouble() ?? 0.0;
            sumTotal += _parseToMinutes(e['totalDuration'] ?? '0h0m').toDouble();
            sumDeep += _parseToMinutes(e['deepSleep'] ?? '0h0m').toDouble();
            sumRem += _parseToMinutes(e['remSleep'] ?? '0h0m').toDouble();
            sumLight += _parseToMinutes(e['lightSleep'] ?? '0h0m').toDouble();
            sumAwake += _parseToMinutes(e['awakeTime'] ?? '0h0m').toDouble();

            final bedObj = _parseTimeObj(e['timeInBed'] as String?);
            final asleepObj = _parseTimeObj(e['timeAsleep'] as String?);
            final wakeObj = _parseTimeObj(e['timeAwake'] as String?);
            final bedMin = _toMinutes(bedObj);
            var asleepMin = _toMinutes(asleepObj);
            var wakeMin = _toMinutes(wakeObj);
            if (asleepObj != null && asleepMin < bedMin) asleepMin += 1440;
            if (wakeObj != null && wakeMin < bedMin) wakeMin += 1440;
            sumBed += bedMin.toDouble();
            sumAsleep += asleepMin.toDouble();
            sumWake += wakeMin.toDouble();
          }

          buckets.add({
            'date': monthStart,
            'sleepScore': sumScore / len,
            'totalDuration': _fmtDuration(sumTotal / len),
            'deepSleep': _fmtDuration(sumDeep / len),
            'remSleep': _fmtDuration(sumRem / len),
            'lightSleep': _fmtDuration(sumLight / len),
            'awakeTime': _fmtDuration(sumAwake / len),
            'timeInBed': _fmtTime(((sumBed / len) % 1440) / 60.0),
            'timeAsleep': _fmtTime(((sumAsleep / len) % 1440) / 60.0),
            'timeAwake': _fmtTime(((sumWake / len) % 1440) / 60.0),
          });
        }

        monthStart = DateTime(monthStart.year, monthStart.month - 1, 1);
      }

      return {'days': days, 'buckets': buckets};
    }

    final size = _bucketSizeForWindow(window);
    final today = DateTime.now();
    final bucketEnd = DateTime(today.year, today.month, today.day);
    final bucketStart = bucketEnd.subtract(Duration(days: window - 1));

    final days = <DateTime>[];
    final buckets = <Map<String, dynamic>?>[];

    for (var end = bucketEnd; !end.isBefore(bucketStart); end = end.subtract(Duration(days: size))) {
      final start = end.subtract(Duration(days: size - 1));
      days.insert(0, end);
      final bStart = start;
      final bEnd = end.add(const Duration(days: 1));
      final entries = data.where((e) {
        final raw = e['date'];
        final dt = raw is DateTime
            ? raw
            : DateTime.parse(raw as String).toLocal();
        return !dt.isBefore(bStart) && dt.isBefore(bEnd);
      }).toList();

      if (entries.isEmpty) {
        buckets.add(null);
        continue;
      }

      final len = entries.length;
      double sumScore = 0,
          sumTotal = 0,
          sumDeep = 0,
          sumRem = 0,
          sumLight = 0,
          sumAwake = 0,
          sumBed = 0,
          sumAsleep = 0,
          sumWake = 0;

      for (var e in entries) {
        sumScore += (e['sleepScore'] as num?)?.toDouble() ?? 0.0;
        sumTotal += _parseToMinutes(e['totalDuration'] ?? '0h0m').toDouble();
        sumDeep += _parseToMinutes(e['deepSleep'] ?? '0h0m').toDouble();
        sumRem += _parseToMinutes(e['remSleep'] ?? '0h0m').toDouble();
        sumLight += _parseToMinutes(e['lightSleep'] ?? '0h0m').toDouble();
        sumAwake += _parseToMinutes(e['awakeTime'] ?? '0h0m').toDouble();

        final bedObj = _parseTimeObj(e['timeInBed'] as String?);
        final asleepObj = _parseTimeObj(e['timeAsleep'] as String?);
        final wakeObj = _parseTimeObj(e['timeAwake'] as String?);
        final bedMin = _toMinutes(bedObj);
        var asleepMin = _toMinutes(asleepObj);
        var wakeMin = _toMinutes(wakeObj);
        if (asleepObj != null && asleepMin < bedMin) asleepMin += 1440;
        if (wakeObj != null && wakeMin < bedMin) wakeMin += 1440;
        sumBed += bedMin.toDouble();
        sumAsleep += asleepMin.toDouble();
        sumWake += wakeMin.toDouble();
      }

      buckets.add({
        'date': bStart,
        'sleepScore': sumScore / len,
        'totalDuration': _fmtDuration(sumTotal / len),
        'deepSleep': _fmtDuration(sumDeep / len),
        'remSleep': _fmtDuration(sumRem / len),
        'lightSleep': _fmtDuration(sumLight / len),
        'awakeTime': _fmtDuration(sumAwake / len),
        'timeInBed': _fmtTime(((sumBed / len) % 1440) / 60.0),
        'timeAsleep': _fmtTime(((sumAsleep / len) % 1440) / 60.0),
        'timeAwake': _fmtTime(((sumWake / len) % 1440) / 60.0),
      });
    }

    return {'days': days, 'buckets': buckets};
  }

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

    final result =
        _buildAggregated(widget.sleepData, windowStart, widget.selectedWindow);
    final days = result['days']!.cast<DateTime>();
    final buckets = result['buckets']!.cast<Map<String, dynamic>?>();

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
