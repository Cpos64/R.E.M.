import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';

/// Parses "h:mm a" into a DateTime, or returns `now` on failure.
DateTime _safeParseTime(String txt) {
  final now = DateTime.now();
  try {
    final dt = DateFormat.jm().parse(txt);
    return DateTime(now.year, now.month, now.day, dt.hour, dt.minute);
  } catch (_) {
    // If parse fails, return now so difference → small
    return now;
  }
}

/// Converts a "XhYm" string into whole minutes.
int parseToMinutes(String input) {
  final hoursMatch = RegExp(r'(\d+)h').firstMatch(input)?.group(1);
  final minsMatch  = RegExp(r'(\d+)m').firstMatch(input)?.group(1);
  final hours = int.tryParse(hoursMatch ?? '0') ?? 0;
  final mins  = int.tryParse(minsMatch  ?? '0') ?? 0;
  return hours * 60 + mins;
}


class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;



  // -------- DREAMS --------
  Future<List<QueryDocumentSnapshot>> getDreams() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('dreams')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs;
  }

  Future<void> saveDream(String title, String description) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('dreams').add({
      'title': title,
      'description': description,
      'timestamp': Timestamp.now(),
      'userId': user.uid,
    });
  }

  Future<void> updateDream(String docId, String newTitle, String newDescription) async {
    await _firestore.collection('dreams').doc(docId).update({
      'title': newTitle,
      'description': newDescription,
    });
  }

  Future<void> deleteDream(String docId) async {
    await _firestore.collection('dreams').doc(docId).delete();
  }

  // -------- SLEEP LOGS --------
  Future<List<QueryDocumentSnapshot>> getSleepLogs() async {
    final user = _auth.currentUser;
    final snapshot = await _firestore
        .collection('sleep_logs')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs;
  }

  Future<List<Map<String, dynamic>>> getLast7SleepLogsForChart() async {
    final user = _auth.currentUser;
    final snapshot = await _firestore
        .collection('sleep_logs')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('timestamp', descending: true)
        .limit(7)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'date': (data['timestamp'] as Timestamp).toDate(),
        'totalSleep': data['totalDuration'] ?? 0,
        'deepSleep': data['deepSleep'] ?? 0,
        'remSleep': data['remSleep'] ?? 0,
        'lightSleep': data['lightSleep'] ?? 0,
        'awakeTime': data['awakeTime'] ?? 0,
        'sleepScore': data['sleepScore'] ?? 0,
        'timeInBed': data['timeInBed'] ?? '',
        'timeAsleep': data['timeAsleep'] ?? '',
        'timeAwake': data['timeAwake'] ?? '',
      };
    }).toList().reversed.toList(); // oldest to newest
  }

Stream<List<Map<String, dynamic>>> watchLogsForChart(int daysBack) {
  final user = _auth.currentUser;
  if (user == null) return const Stream.empty();

  // 1️⃣ compute midnight‐based cutoff
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final cutoff = startOfToday.subtract(Duration(days: daysBack - 1));

  // 2️⃣ query after cutoff, ascending
  return _firestore
      .collection('sleep_logs')
      .where('userId', isEqualTo: user.uid)
      .where('timestamp',
             isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snap) {
        return snap.docs.map((doc) {
          final d = doc.data();
          return {
            'date':       (d['timestamp'] as Timestamp).toDate(),
            'totalDuration': d['totalDuration'] ?? '',
            'deepSleep':  d['deepSleep']      ?? '',
            'remSleep':   d['remSleep']       ?? '',
            'lightSleep': d['lightSleep']     ?? '',
            'awakeTime':  d['awakeTime']      ?? '',
            'sleepScore': d['sleepScore']     ?? 0,
            'timeInBed':  d['timeInBed']      ?? '',
            'timeAsleep': d['timeAsleep']     ?? '',
            'timeAwake':  d['timeAwake']      ?? '',
            'notes':      d['notes']          ?? '',
          };
        }).toList();
      });
}

Future<void> saveSleepLogAuto({
  required String totalDuration,
  required String deepSleep,
  required String remSleep,
  required String awakeTime,
  required String timeInBed,
  required String timeAsleep,
  required String timeAwake,
  required String quality,
  String? notes,
  required DateTime date,
}) async {
  final user = _auth.currentUser;
  if (user == null) return;


  final total = parseToMinutes(totalDuration);
  final deep = parseToMinutes(deepSleep);
  final rem = parseToMinutes(remSleep);
  final awake = parseToMinutes(awakeTime);
  final lightMin = ((total - (deep + rem + awake)).clamp(0, total));

  final avgs = await get30DayAverageBedAndWakeTime();
  final rawAvgBed  = avgs['averageBedtimeStr']!;
  final rawAvgWake = avgs['averageWakeTimeStr']!;

    // FALLBACK if no average yet:
  final avgBedStr  = rawAvgBed.isNotEmpty  ? rawAvgBed  : timeInBed;
  final avgWakeStr = rawAvgWake.isNotEmpty ? rawAvgWake : timeAwake;

  final sleepScore = _computeSleepScore(
    totalMinutes: total,
    deepMinutes: deep,
    remMinutes: rem,
    awakeMinutes: awake,
    timeInBedStr: timeInBed,
    timeAsleepStr: timeAsleep,
    averageBedtimeStr: avgBedStr,
    averageWakeTimeStr: avgWakeStr,
  );

final lightStr = '${lightMin ~/ 60}h${lightMin % 60}m';

DateTime parsedTimeInBed = _safeParseTime(timeInBed);
DateTime parsedTimeAsleep = _safeParseTime(timeAsleep);
DateTime parsedTimeAwake = _safeParseTime(timeAwake);

DateTime now = DateTime.now();
parsedTimeInBed = DateTime(now.year, now.month, now.day, parsedTimeInBed.hour, parsedTimeInBed.minute);
parsedTimeAsleep = DateTime(now.year, now.month, now.day, parsedTimeAsleep.hour, parsedTimeAsleep.minute);
parsedTimeAwake = DateTime(now.year, now.month, now.day, parsedTimeAwake.hour, parsedTimeAwake.minute);

// Handle midnight rollover if needed
if (parsedTimeAsleep.isBefore(parsedTimeInBed)) {
  parsedTimeAsleep = parsedTimeAsleep.add(const Duration(days: 1));
}
if (parsedTimeAwake.isBefore(parsedTimeAsleep)) {
  parsedTimeAwake = parsedTimeAwake.add(const Duration(days: 1));
}

// Calculate time to fall asleep
Duration timeToFallAsleep = parsedTimeAsleep.difference(parsedTimeInBed);
final timeToFallAsleepReadable = '${timeToFallAsleep.inMinutes} min';
final timeToFallAsleepISO = timeToFallAsleep.toString(); // e.g., "0:15:00.000000"


  final data = {
    "totalDuration": totalDuration,
    "deepSleep": deepSleep,
    "remSleep": remSleep,
    "lightSleep": lightStr,
    "awakeTime": awakeTime,
    "sleepScore": sleepScore,
    "timeAsleep": timeAsleep,
    "timeAwake": timeAwake,
    "timeInBed": timeInBed,
    "timeToFallAsleep": timeToFallAsleepReadable,
    "timeToFallAsleepISO": timeToFallAsleepISO,
    "quality": quality,
    "notes": notes ?? "",
    "timestamp": Timestamp.fromDate(date),
    "userId": user.uid,
        // — **NEW** integer fields for averaging! —
    "totalMinutes":  total,
    "deepMinutes":   deep,
    "remMinutes":    rem,
    "awakeMinutes":  awake,
  };

  print('Saving sleep log (auto) for userId: ${user.uid}');
  print('Data: $data');

  await _firestore.collection('sleep_logs').add(data);
}

/// Returns a map with formatted 30-day average bedtime & wake time for the current user.
Future<Map<String, String>> get30DayAverageBedAndWakeTime({int days = 30}) async {
  final user = _auth.currentUser;
  if (user == null) return {'averageBedtimeStr': '', 'averageWakeTimeStr': ''};

 // Query the last [days] sleep logs for this user
  final snapshot = await _firestore
      .collection('sleep_logs') // adjust to your actual collection name
      .where('userId', isEqualTo: user.uid)
      .orderBy('timestamp', descending: true)
      .limit(days)
      .get();

  if (snapshot.docs.isEmpty) {
    return {'averageBedtimeStr': '', 'averageWakeTimeStr': ''};
  }

  // Helper function to convert time strings to minutes
int _toMinutes(String txt) {
  // Try 12-hour parse first…
  try {
    final dt = DateFormat.jm().parse(txt);
    return dt.hour * 60 + dt.minute;
  } catch (_) {
    // …then fall back to ISO-8601 if present
    try {
      final dt2 = DateTime.parse(txt);
      return dt2.hour * 60 + dt2.minute;
    } catch (_) {
      // If *that* also fails, give up and return 0
      return 0;
    }
  }
}


  // Collect beds and wakes
  final bedMinutes = <int>[];
  final wakeMinutes = <int>[];

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final bedStr = data['timeInBed'] as String? ?? '';
    final totalMin = data['totalMinutes'] as int? ?? 0;
    final awakeMin = data['awakeMinutes'] as int? ?? 0;
    if (bedStr.isEmpty) continue;

    final bedMin = _toMinutes(bedStr);
    final wakeMin = (bedMin + totalMin + awakeMin) % 1440;

    bedMinutes.add(bedMin);
    wakeMinutes.add(wakeMin);
  }

  // Circular mean helper for times around midnight
  int _circularMean(List<int> mins) {
    final rad = mins.map((m) => 2 * pi * (m / 1440));
    final x = rad.map(cos).reduce((a, b) => a + b) / rad.length;
    final y = rad.map(sin).reduce((a, b) => a + b) / rad.length;
    final angle = atan2(y, x);
    final normalized = angle < 0 ? angle + 2 * pi : angle;
    return (normalized / (2 * pi) * 1440).round();
  }

  // Compute the two averages
  final avgBedMin = _circularMean(bedMinutes);
  final avgWakeMin = _circularMean(wakeMinutes);

  // Format back to "h:mm a"
  String _format(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final dt = DateTime(0, 0, 0, h, m);
    return DateFormat.jm().format(dt);
  }

  return {
    'averageBedtimeStr': _format(avgBedMin),
    'averageWakeTimeStr': _format(avgWakeMin),
  };
}

// Magic Sleep Score Computation:

double _computeSleepScore({
  required int totalMinutes,
  required int deepMinutes,
  required int remMinutes,
  required int awakeMinutes,
  required String timeInBedStr,       // e.g. "10:30 PM"
  required String timeAsleepStr,      // e.g. "10:50 PM"
  required String averageBedtimeStr,  // from get30DayAverageBedAndWakeTime()
  required String averageWakeTimeStr, // from get30DayAverageBedAndWakeTime()
}) {
  if (totalMinutes <= 0) return 0;

  // 1) Duration Score (0–22)
  double durationScore;
  if (totalMinutes <= 360) {
    durationScore = 0;
  } else if (totalMinutes <= 420) {
    durationScore = (totalMinutes - 360) / 60 * 11;
  } else if (totalMinutes <= 540) {
    durationScore = 11 + (totalMinutes - 420) / 120 * 11;
  } else {
    durationScore = 22;
  }

  // 2) Efficiency Score (0–14)
  final efficiency = totalMinutes / (totalMinutes + awakeMinutes);
  double efficiencyScore;
  if (efficiency <= 0.75) {
    efficiencyScore = 0;
  } else if (efficiency <= 0.85) {
    efficiencyScore = (efficiency - 0.75) / 0.10 * 7;
  } else if (efficiency <= 0.95) {
    efficiencyScore = 7 + (efficiency - 0.85) / 0.10 * 7;
  } else {
    efficiencyScore = 14;
  }

  // 3) Deep % Score (0–22)
  final deepPct = deepMinutes / totalMinutes;
  double deepScore;
  if (deepPct <= 0.10) {
    deepScore = 0;
  } else if (deepPct <= 0.15) {
    deepScore = (deepPct - 0.10) / 0.05 * 11;
  } else if (deepPct <= 0.20) {
    deepScore = 11 + (deepPct - 0.15) / 0.05 * 11;
  } else {
    deepScore = 22;
  }

  // 4) REM % Score (0–22)
  final remPct = remMinutes / totalMinutes;
  double remScore;
  if (remPct <= 0.15) {
    remScore = 0;
  } else if (remPct <= 0.20) {
    remScore = (remPct - 0.15) / 0.05 * 11;
  } else if (remPct <= 0.25) {
    remScore = 11 + (remPct - 0.20) / 0.05 * 11;
  } else {
    remScore = 22;
  }

  // 5) Awake-time Penalty (0–6)
  final awakePct = awakeMinutes / totalMinutes;
  double awakeScore;
  if (awakePct < 0.03) {
    awakeScore = 6;
  } else if (awakePct <= 0.07) {
    awakeScore = (0.07 - awakePct) / 0.04 * 6;
  } else {
    awakeScore = 0;
  }

  // 6) Sleep-Onset Latency (0–6)
  final inBed  = _safeParseTime(timeInBedStr);
  final asleep = _safeParseTime(timeAsleepStr);
  final latency = asleep.difference(inBed).inMinutes.clamp(0, 60);
  double latencyScore;
  if (latency <= 15) {
    latencyScore = 6;
  } else if (latency <= 30) {
    latencyScore = (30 - latency) / 15 * 6;
  } else {
    latencyScore = 0;
  }

  // 7) Consistency Score (0–8)
  final avgBed  = _safeParseTime(averageBedtimeStr);
  final avgWake = _safeParseTime(averageWakeTimeStr);
  final actualWake = _safeParseTime(timeInBedStr)
      .add(Duration(minutes: totalMinutes + awakeMinutes));

  final bedDelta  = (inBed.difference(avgBed).inMinutes).abs();
  final wakeDelta = (actualWake.difference(avgWake).inMinutes).abs();

  double _subConsistency(int diff) {
    if (diff <= 20) {
      return 4;
    } else if (diff <= 40) {
      return (40 - diff) / 20 * 4;
    } else {
      return 0;
    }
  }
  final consistencyScore = _subConsistency(bedDelta) + _subConsistency(wakeDelta);

  // ── Sum & clamp ──
  final raw = durationScore
            + efficiencyScore
            + deepScore
            + remScore
            + awakeScore
            + latencyScore
            + consistencyScore;

  return raw.clamp(0, 100).roundToDouble();
}


/// Updates an existing sleep_log doc with recalculated sleepScore and fields.
Future<void> updateSleepLogAuto({
  required String docId,
  required String totalDuration,
  required String deepSleep,
  required String remSleep,
  required String awakeTime,
  required String timeInBed,
  required String timeAsleep,
  required String timeAwake,
  required String quality,
  String? notes,
  required DateTime date,
}) async {
  final user = _auth.currentUser;
  if (user == null) return;

DateTime parsedTimeInBed = _safeParseTime(timeInBed);
DateTime parsedTimeAsleep = _safeParseTime(timeAsleep);
DateTime parsedTimeAwake = _safeParseTime(timeAwake);

DateTime now = DateTime.now();
parsedTimeInBed = DateTime(now.year, now.month, now.day, parsedTimeInBed.hour, parsedTimeInBed.minute);
parsedTimeAsleep = DateTime(now.year, now.month, now.day, parsedTimeAsleep.hour, parsedTimeAsleep.minute);
parsedTimeAwake = DateTime(now.year, now.month, now.day, parsedTimeAwake.hour, parsedTimeAwake.minute);

// Handle midnight rollover if needed
if (parsedTimeAsleep.isBefore(parsedTimeInBed)) {
  parsedTimeAsleep = parsedTimeAsleep.add(const Duration(days: 1));
}
if (parsedTimeAwake.isBefore(parsedTimeAsleep)) {
  parsedTimeAwake = parsedTimeAwake.add(const Duration(days: 1));
}

// Calculate time to fall asleep
Duration timeToFallAsleep = parsedTimeAsleep.difference(parsedTimeInBed);
final timeToFallAsleepReadable = '${timeToFallAsleep.inMinutes} min';
final timeToFallAsleepISO = timeToFallAsleep.toString(); // e.g., "0:15:00.000000"


  final total = parseToMinutes(totalDuration);
  final deep  = parseToMinutes(deepSleep);
  final rem   = parseToMinutes(remSleep);
  final awake = parseToMinutes(awakeTime);
  final lightMin = ((total - (deep + rem + awake)).clamp(0, total));


  // 2) Fetch 30-day averages
  final avgs      = await get30DayAverageBedAndWakeTime();
  final rawAvgBed = avgs['averageBedtimeStr']!;
  final rawAvgWake= avgs['averageWakeTimeStr']!;
  final avgBedStr = rawAvgBed.isNotEmpty ? rawAvgBed : timeInBed;
  final avgWakeStr= rawAvgWake.isNotEmpty ? rawAvgWake: timeAwake;

  // 3) Compute new score
  final sleepScore = _computeSleepScore(
    totalMinutes:       total,
    deepMinutes:        deep,
    remMinutes:         rem,
    awakeMinutes:       awake,
    timeInBedStr:       timeInBed,
    timeAsleepStr:      timeAsleep,
    averageBedtimeStr:  avgBedStr,
    averageWakeTimeStr: avgWakeStr,
  );

  // 4) Build updated data map
  final lightStr = '${lightMin ~/ 60}h${lightMin % 60}m';
  final data = {
    "totalDuration":     totalDuration,
    "deepSleep":         deepSleep,
    "remSleep":          remSleep,
    "lightSleep":        lightStr,
    "awakeTime":         awakeTime,
    "totalMinutes":      total,
    "deepMinutes":       deep,
    "remMinutes":        rem,
    "awakeMinutes":      awake,
    "sleepScore":        sleepScore,
    "timeInBed":         timeInBed,
    "timeAsleep":        timeAsleep,
    "timeAwake":         timeAwake,
    "quality":           quality,
    "notes":             notes ?? "",
    "timestamp":         Timestamp.fromDate(date),
    "userId":            user.uid,
    "timeToFallAsleep": timeToFallAsleepReadable,
    "timeToFallAsleepISO": timeToFallAsleepISO,
  };

  // 5) Write it back
  await _firestore
    .collection('sleep_logs')
    .doc(docId)
    .update(data);
}

  Future<void> deleteSleepLog(String docId) async {
    await _firestore.collection('sleep_logs').doc(docId).delete();
  }

  // -------- THEME PREFERENCES --------
  Future<void> saveUserTheme(bool isDarkTheme) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'isDarkTheme': isDarkTheme,
    }, SetOptions(merge: true));
  }

  Future<bool> loadUserTheme() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['isDarkTheme'] ?? false;
  }
}

