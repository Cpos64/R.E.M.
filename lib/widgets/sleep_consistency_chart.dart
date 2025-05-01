import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SleepConsistencyChart extends StatelessWidget {
  final List<Map<String, dynamic>> sleepData;

  const SleepConsistencyChart({
    Key? key,
    required this.sleepData,
  }) : super(key: key);
  

/// Parse either an ISO timestamp or a "h:mm a" string into a decimal hour.
double _parseTime(String? text) {
  if (text == null || text.isEmpty) return 0.0;

  // 1) Try ISO-8601 first:
  final iso = DateTime.tryParse(text);
  if (iso != null) {
    // Use the hour/minute of the parsed DateTime
    return iso.hour + iso.minute / 60.0;
  }

  // 2) Fallback to parsing "10:30 PM" style:
  try {
    final dt = DateFormat.jm().parse(text);
    return dt.hour + dt.minute / 60.0;
  } catch (_) {
    return 0.0;
  }
}

/// Renders a Garmin-style two-column tooltip.
Widget _buildTwoColumnTooltip({
  required DateTime date,
  required String leftLabel,
  required String leftTime,
  required String rightLabel,
  required String rightTime,
}) {
  final dateStr = DateFormat.MMMMd().format(date); // e.g. “April 27”
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.grey[900]!.withOpacity(0.9),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Date header (smaller, semi-opaque)
        Text(
          dateStr,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),

        // Two-column row: left = earlier, right = later
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // LEFT column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(leftTime, style: TextStyle(color: Colors.white, fontSize: 12)),
                  Text(leftLabel, style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),

            // small gutter
            const SizedBox(width: 12),

            // RIGHT column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(rightTime, style: TextStyle(color: Colors.white, fontSize: 12)),
                  Text(rightLabel, style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
// 1. Compute averages exactly as before, from only the actual entries:
double sumBed = 0, sumWake = 0;
for (var e in sleepData) {
 final rawBed = _parseTime(e['timeInBed'] as String?);
  // only subtract 24 if it actually came in as >12 (i.e. an evening time)
  final bedRel = rawBed > 12 ? rawBed - 24 : rawBed;

  final wakeRel = _parseTime(e['timeAwake'] as String?);
  sumBed  += bedRel;
  sumWake += wakeRel;
}
final avgBed  = sumBed  / sleepData.length;
final avgWake = sumWake / sleepData.length;

   // ── 1) Right after you compute avgBed & avgWake ──
double sumAsleep = 0;
for (var e in sleepData) {
  // parse exactly as you do for each day, subtracting 24h if needed
  final raw = _parseTime(e['timeAsleep'] as String?);
  final rel = raw > 12 ? raw - 24 : raw;
  sumAsleep += rel;
}
final avgAsleep = sumAsleep / sleepData.length;

// helper to show hh:mm AM/PM everywhere
String _fmt(double v) {
  final h = v.floor();
  final m = ((v - h) * 60).round();
  return DateFormat.jm().format(DateTime(0, 0, 0, h, m));
}
final avgBedStr    = _fmt(avgBed);
final avgAsleepStr = _fmt(avgAsleep);
final avgWakeStr   = _fmt(avgWake);


// 2. Build a 7-day window ending today:
final today = DateTime.now();
final last7 = List<DateTime>.generate(7, (i) {
  final d = today.subtract(Duration(days: 6 - i));
  return DateTime(d.year, d.month, d.day);
});

// 3. Now build seven groups—using real data when present,
//    or two transparent zero-height rods when missing:
final rods = <BarChartGroupData>[];
for (var i = 0; i < last7.length; i++) {
  final day = last7[i];
      // 3a) Find all entries matching this calendar day:
      final matches = sleepData.where((e) {
        final dt = e['date'] as DateTime;
        return dt.year == day.year
            && dt.month == day.month
            && dt.day == day.day;
      }).toList();

      if (matches.isNotEmpty) {
        // We have real data—use the first match.
        final entry = matches.first;

        // Print the entry for debugging:
        print('Map for $day: ${entry.keys} → values: $entry');

        // 1) Parse all three times (parseTime already gives 0.0 on null)
        final bedParsed    = _parseTime(entry['timeInBed']   as String?);
        final asleepParsed = _parseTime(entry['timeAsleep']  as String?);
        final wakeParsed   = _parseTime(entry['timeAwake']   as String?);

        // 2) Only subtract 24 if the hour is > 12 (i.e. after noon ⇒ we want "previous day")
        final bedRel    = bedParsed    > 12 ? bedParsed    - 24 : bedParsed;
        final asleepRel = asleepParsed > 12 ? asleepParsed - 24 : asleepParsed;
        final wakeRel   = wakeParsed; // wake times we keep as-is (0–23)


        print('Day $i (${last7[i]}): '
          'bed=$bedRel, asleep=$asleepRel, wake=$wakeRel');

        rods.add(BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              fromY: bedRel,
              toY:   asleepRel,
              width: 10,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            BarChartRodData(
              fromY: asleepRel,
              toY:   wakeRel,
              width: 10,
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ));
      } else {
        // No data for this day—draw two transparent placeholders:
        rods.add(BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(fromY: 0, toY: 0, width: 10, color: Colors.transparent),
            BarChartRodData(fromY: 0, toY: 0, width: 10, color: Colors.transparent),
          ],
        ));
      }
}


  
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'Sleep Consistency',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // The BarChart itself fills the remaining height from the pager's SizedBox( height:380 )
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 40.0),
          child: BarChart(
BarChartData(
barTouchData: BarTouchData(
  enabled: true,
  touchTooltipData: BarTouchTooltipData(
    fitInsideHorizontally: true,
    fitInsideVertically:   true,
    tooltipPadding:        const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    tooltipMargin:         4,

    // 1) Background color for the tooltip box
    getTooltipColor: (group) => Colors.grey[900]!.withOpacity(0.9),

    // 2) Rich-text tooltip with varied font sizes and non-breaking spaces
    getTooltipItem: (group, groupIndex, rod, rodIndex) {
      // a) Determine the date for this bar
      final date = last7[group.x.toInt()];

      // b) Find the matching entry (or empty map if none)
      final entry = sleepData.firstWhere(
        (e) {
          final dt = e['date'] as DateTime;
          return dt.year == date.year &&
                 dt.month == date.month &&
                 dt.day == date.day;
        },
        orElse: () => <String, dynamic>{},
      );

      // c) Helper to normalize any ISO or “h:mm a” string
String fmt(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  final iso = DateTime.tryParse(raw);
  String out;
  if (iso != null) {
    out = DateFormat.jm().format(iso);
  } else {
    try {
      out = DateFormat.jm().format(DateFormat.jm().parse(raw));
    } catch (_) {
      return raw;
    }
  }
  // Prevent the time from splitting before AM/PM:
  return out.replaceAll(' ', '\u00A0');
}

      // d) Pull in the three times
      final bed    = fmt(entry['timeInBed']  as String?);
      final asleep = fmt(entry['timeAsleep'] as String?);
      final wake   = fmt(entry['timeAwake']  as String?);

      // e) Decide which segment (rodIndex 0 = in-bed→asleep, 1 = asleep→wake)
      final leftTime   = rodIndex == 0 ? bed    : asleep;
      final rightTime  = rodIndex == 0 ? asleep : wake;
      final leftLabel  = rodIndex == 0 ? 'Bedtime' : 'Asleep';
      final rightLabel = rodIndex == 0 ? 'Asleep'  : 'Wake';

      // f) Use non-breaking spaces so the two “columns” never wrap
      const sep = '\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0';
      final line1 = '$leftTime$sep$rightTime';
      final line2 = '$leftLabel$sep$rightLabel';

      // g) Build and return a rich-text tooltip
      return BarTooltipItem(
        '',
        const TextStyle(), // we’ll use children spans only
        children: [
          // Date header (smaller, semi-opaque)
          TextSpan(
            text: '${DateFormat.MMMMd().format(date)}\n',
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),

          // Times row (larger & bold)
          TextSpan(
            text: '$line1\n',
            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),

          // Labels row (small, semi-opaque)
          TextSpan(
            text: line2,
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      );
    },
  ),
),


              alignment: BarChartAlignment.spaceAround,
              groupsSpace: 4,
              minY: -6,   // 18:00 → -6.0
              maxY: 12,   // 12:00 → +12.0
              barGroups: rods,

              gridData: FlGridData(
                show: true,
                horizontalInterval: 3,
                verticalInterval: 1,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white24, strokeWidth: 0.5),
                getDrawingVerticalLine: (_) =>
                    const FlLine(color: Colors.white24, strokeWidth: 0.5),
              ),


titlesData: FlTitlesData(
  leftTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      interval: 6,      // only every 6 hours
      reservedSize: 80, // more room for the text
      getTitlesWidget: (val, meta) {
        // 1) Build the label widget
        Widget label;
        final hour = (val % 24 + 24) % 24;
        if (hour == 0)      label = const Text('12 AM', style: TextStyle(fontSize: 10));
        else if (hour == 6) label = const Text('6 AM',  style: TextStyle(fontSize: 10));
        else if (hour == 12)label = const Text('12 PM', style: TextStyle(fontSize: 10));
        else if (hour == 18)label = const Text('6 PM',  style: TextStyle(fontSize: 10));
        else                label = const SizedBox.shrink();

        // 2) Wrap it in a Padding widget
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: label,
        );
      },
    ),
  ),


                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                  getTitlesWidget: (val, _) {
                    final idx = val.toInt();
                    if (idx < 0 || idx >= last7.length) return const SizedBox.shrink();
                    return Text(DateFormat('E').format(last7[idx]), style: const TextStyle(fontSize: 10));
                  },

                  ),
                ),


                topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),

              // 2.a) The translucent “zone” for bed→asleep
   rangeAnnotations: RangeAnnotations(
     horizontalRangeAnnotations: [
       HorizontalRangeAnnotation(
         y1: avgBed,
         y2: avgAsleep,
         color: Theme.of(context)
             .colorScheme
             .primary
             .withOpacity(0.15),
       ),
     ],
   ),

  extraLinesData: ExtraLinesData(
    horizontalLines: [
      // // 1) Avg In-Bed (solid)
      HorizontalLine(
        y: avgBed,
        color: Colors.white,
        strokeWidth: 1,
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.bottomLeft,
          labelResolver: (_) => '$avgBedStr',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ),

      // 2) Avg Asleep (solid)
      HorizontalLine(
        y: avgAsleep,
        color: Colors.white,
        strokeWidth: 1,
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topLeft,
          labelResolver: (_) => '$avgAsleepStr',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ),


      // 3) Avg Wake (dashed)
      HorizontalLine(
        y: avgWake,
        color: Colors.white,
        strokeWidth: 1,
        dashArray: [4, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.bottomLeft,
          labelResolver: (_) => '$avgWakeStr',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ),
    ],
  ),


              borderData: FlBorderData(show: true),
            ),
          ),
        ), 
        ),
    


        const SizedBox(height: 8),
        // ── Legend ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                label: 'In Bed → Asleep',
              ),
              const SizedBox(width: 16),
              _LegendDot(
                color: Theme.of(context).colorScheme.primary,
                label: 'Asleep → Wake',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}

