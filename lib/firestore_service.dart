import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:dart_sentiment/dart_sentiment.dart';

/// Parses "h:mm a" into a DateTime, or returns `now` on failure.
DateTime _safeParseTime(String txt) {
  final now = DateTime.now();
  try {
    final dt = DateFormat.jm().parse(txt);
    return DateTime(now.year, now.month, now.day, dt.hour, dt.minute);
  } catch (_) {
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

final _sentiment = Sentiment();

double _analyzeSentiment(String text) {
  final res = _sentiment.analysis(text, emoji: true);
  // `res['score']` is an int; convert to double
  return (res['score'] as num).toDouble();
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth      _auth      = FirebaseAuth.instance;

  // ───────── DREAMS ─────────────────────────────────────────────────────────

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

/// Add a dream entry with sentimentScore and tags.
/// If you later query by tags, create an "array-contains" index on (userId, genres).
  /// in the Firestore console for performant queries.
Future<void> saveDream({
  required String title,
  required String description,
  required List<String> genres,
  required int recallRating,
  required DateTime date,
}) async {
  final user = _auth.currentUser;
  if (user == null) return;

  final safeGenres = genres.isNotEmpty ? genres : ['Other'];
  final sentimentScore = _analyzeSentiment(description);

  await _firestore.collection('dreams').add({
    'title':          title,
    'description':    description,
    'sentimentScore': sentimentScore,
    'genres':         safeGenres,        // ← store list, not a single string
    'recallRating':   recallRating,
    'timestamp':      Timestamp.fromDate(date),
    'userId':         user.uid,
  });
}


  /// Update a dream entry, recomputing sentimentScore if the description changed.
Future<void> updateDream({
  required String id,
  required String title,
  required String description,
  required List<String> genres,
  required int recallRating,
  required DateTime date,
}) async {
  final safeGenres = genres.isNotEmpty ? genres : ['Other'];
  final sentimentScore = _analyzeSentiment(description);

  await _firestore.collection('dreams').doc(id).update({
    'title':          title,
    'description':    description,
    'sentimentScore': sentimentScore,
    'genres':         safeGenres,      // ← update list field
    'recallRating':   recallRating,
    'timestamp':      Timestamp.fromDate(date),
  });
}

  Future<void> deleteDream(String docId) async {
    await _firestore.collection('dreams').doc(docId).delete();
  }

  // -------- SLEEP LOGS --------

  Future<List<QueryDocumentSnapshot>> getSleepLogs() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final snapshot = await _firestore
      .collection('sleep_logs')
      .where('userId', isEqualTo: user.uid)
      .orderBy('timestamp', descending: true)
      .get();
    return snapshot.docs;
  }

  Future<List<Map<String, dynamic>>> getLast7SleepLogsForChart() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final snapshot = await _firestore
      .collection('sleep_logs')
      .where('userId', isEqualTo: user.uid)
      .orderBy('timestamp', descending: true)
      .limit(7)
      .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'date':          (data['timestamp'] as Timestamp).toDate(),
        'totalDuration': data['totalDuration'] ?? 0,
        'deepSleep':     data['deepSleep']      ?? 0,
        'remSleep':      data['remSleep']       ?? 0,
        'lightSleep':    data['lightSleep']     ?? 0,
        'awakeTime':     data['awakeTime']      ?? 0,
        'sleepScore':    data['sleepScore']     ?? 0,
        'timeInBed':     data['timeInBed']      ?? '',
        'timeAsleep':    data['timeAsleep']     ?? '',
        'timeAwake':     data['timeAwake']      ?? '',
      };
    }).toList().reversed.toList();
  }

  Stream<List<Map<String, dynamic>>> watchLogsForChart(int daysBack) {
    final user = _auth.currentUser;
    if (user == null) return Stream<List<Map<String, dynamic>>>.empty();

    final now          = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final cutoff       = startOfToday.subtract(Duration(days: daysBack - 1));

    return _firestore
      .collection('sleep_logs')
      .where('userId', isEqualTo: user.uid)
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
        final d = doc.data();
        return {
          'date':          (d['timestamp'] as Timestamp).toDate(),
          'totalDuration': d['totalDuration'] ?? 0,
          'deepSleep':     d['deepSleep']      ?? 0,
          'remSleep':      d['remSleep']       ?? 0,
          'lightSleep':    d['lightSleep']     ?? 0,
          'awakeTime':     d['awakeTime']      ?? 0,
          'sleepScore':    d['sleepScore']     ?? 0,
          'timeInBed':     d['timeInBed']      ?? '',
          'timeAsleep':    d['timeAsleep']     ?? '',
          'timeAwake':     d['timeAwake']      ?? '',
          'notes':         d['notes']          ?? '',
        };
      }).toList());
  }

  Future<void> saveSleepLogAuto({
    required String   totalDuration,
    required String   deepSleep,
    required String   remSleep,
    required String   awakeTime,
    required String   timeInBed,
    required String   timeAsleep,
    required String   timeAwake,
    required String   quality,
             String?  notes,
    required DateTime date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final total    = parseToMinutes(totalDuration);
    final deep     = parseToMinutes(deepSleep);
    final rem      = parseToMinutes(remSleep);
    final awake    = parseToMinutes(awakeTime);
    final lightMin = ((total - (deep + rem + awake)).clamp(0, total)).toInt();

    final avgs       = await get30DayAverageBedAndWakeTime();
    final rawAvgBed  = avgs['averageBedtimeStr']!;
    final rawAvgWake = avgs['averageWakeTimeStr']!;
    final avgBedStr  = rawAvgBed.isNotEmpty  ? rawAvgBed  : timeInBed;
    final avgWakeStr = rawAvgWake.isNotEmpty ? rawAvgWake : timeAwake;

    final sleepScore = _computeSleepScore(
      totalMinutes:       total,
      deepMinutes:        deep,
      remMinutes:         rem,
      awakeMinutes:       awake,
      timeInBedStr:       timeInBed,
      timeAsleepStr:      timeAsleep,
      averageBedtimeStr:  avgBedStr,
      averageWakeTimeStr: avgWakeStr,
      timeAwakeStr:       timeAwake,
    );

    final lightStr = '${lightMin ~/ 60}h${lightMin % 60}m';

    DateTime pInBed  = _safeParseTime(timeInBed);
    DateTime pAsleep = _safeParseTime(timeAsleep);
    DateTime pAwake  = _safeParseTime(timeAwake);
    final nowDT = DateTime.now();
    pInBed  = DateTime(nowDT.year, nowDT.month, nowDT.day, pInBed.hour,  pInBed.minute);
    pAsleep = DateTime(nowDT.year, nowDT.month, nowDT.day, pAsleep.hour, pAsleep.minute);
    pAwake  = DateTime(nowDT.year, nowDT.month, nowDT.day, pAwake.hour,  pAwake.minute);

    if (pAsleep.isBefore(pInBed))  pAsleep = pAsleep.add(Duration(days: 1));
    if (pAwake.isBefore(pAsleep))  pAwake  = pAwake.add(Duration(days: 1));

    final timeToFall   = pAsleep.difference(pInBed);
    final fallReadable = '${timeToFall.inMinutes} min';
    final fallISO      = timeToFall.toString();

    final data = {
      'totalDuration':     totalDuration,
      'deepSleep':         deepSleep,
      'remSleep':          remSleep,
      'lightSleep':        lightStr,
      'awakeTime':         awakeTime,
      'totalMinutes':      total,
      'deepMinutes':       deep,
      'remMinutes':        rem,
      'awakeMinutes':      awake,
      'sleepScore':        sleepScore,
      'timeInBed':         timeInBed,
      'timeAsleep':        timeAsleep,
      'timeAwake':         timeAwake,
      'quality':           quality,
      'notes':             notes ?? '',
      'timestamp':         Timestamp.fromDate(date),
      'userId':            user.uid,
      'timeToFallAsleep':  fallReadable,
      'timeToFallAsleepISO': fallISO,
    };

    await _firestore.collection('sleep_logs').add(data);
  }

Future<void> updateSleepLogAuto({
  required String   docId,
  required String   totalDuration,
  required String   deepSleep,
  required String   remSleep,
  required String   awakeTime,
  required String   timeInBed,
  required String   timeAsleep,
  required String   timeAwake,
  required String   quality,
           String?  notes,
  required DateTime date,
}) async {
  final user = _auth.currentUser;
  if (user == null) return;

  // 1) Parse durations
  final total    = parseToMinutes(totalDuration);
  final deep     = parseToMinutes(deepSleep);
  final rem      = parseToMinutes(remSleep);
  final awake    = parseToMinutes(awakeTime);
  final lightMin = ((total - (deep + rem + awake)).clamp(0, total)).toInt();
  final lightStr = '${lightMin ~/ 60}h${lightMin % 60}m';

  // 2) Recompute 30-day averages
  final avgs       = await get30DayAverageBedAndWakeTime();
  final rawAvgBed  = avgs['averageBedtimeStr']!;
  final rawAvgWake = avgs['averageWakeTimeStr']!;
  final avgBedStr  = rawAvgBed.isNotEmpty  ? rawAvgBed  : timeInBed;
  final avgWakeStr = rawAvgWake.isNotEmpty ? rawAvgWake : timeAwake;

  // 3) Compute new sleepScore
  final sleepScore = _computeSleepScore(
    totalMinutes:       total,
    deepMinutes:        deep,
    remMinutes:         rem,
    awakeMinutes:       awake,
    timeInBedStr:       timeInBed,
    timeAsleepStr:      timeAsleep,
    timeAwakeStr:       timeAwake,        // make sure this is passed
    averageBedtimeStr:  avgBedStr,
    averageWakeTimeStr: avgWakeStr,
  );

  // 4) Recompute time-to-fall-asleep
  DateTime pInBed  = _safeParseTime(timeInBed);
  DateTime pAsleep = _safeParseTime(timeAsleep);
  DateTime pAwake  = _safeParseTime(timeAwake);
  final nowDT = DateTime.now();
  pInBed  = DateTime(nowDT.year, nowDT.month, nowDT.day, pInBed.hour,  pInBed.minute);
  pAsleep = DateTime(nowDT.year, nowDT.month, nowDT.day, pAsleep.hour, pAsleep.minute);
  pAwake  = DateTime(nowDT.year, nowDT.month, nowDT.day, pAwake.hour,  pAwake.minute);

  if (pAsleep.isBefore(pInBed))  pAsleep = pAsleep.add(Duration(days: 1));
  if (pAwake.isBefore(pAsleep))  pAwake  = pAwake.add(Duration(days: 1));

  final timeToFall   = pAsleep.difference(pInBed);
  final fallReadable = '${timeToFall.inMinutes} min';
  final fallISO      = timeToFall.toString();

  // 5) Write updated fields back to Firestore
  await _firestore
      .collection('sleep_logs')
      .doc(docId)
      .update({
        'totalDuration':      totalDuration,
        'deepSleep':          deepSleep,
        'remSleep':           remSleep,
        'lightSleep':         lightStr,
        'awakeTime':          awakeTime,
        'totalMinutes':       total,
        'deepMinutes':        deep,
        'remMinutes':         rem,
        'awakeMinutes':       awake,
        'sleepScore':         sleepScore,
        'timeInBed':          timeInBed,
        'timeAsleep':         timeAsleep,
        'timeAwake':          timeAwake,
        'timeToFallAsleep':   fallReadable,     // now defined
        'timeToFallAsleepISO': fallISO,         // now defined
        'quality':            quality,
        'notes':              notes ?? '',
        'timestamp':          Timestamp.fromDate(date),
        'userId':             user.uid,
      });
}

  Future<void> deleteSleepLog(String docId) async {
    await _firestore.collection('sleep_logs').doc(docId).delete();
  }

  // -------- THEME PREFERENCES --------

  Future<void> saveUserTheme(bool isDarkTheme) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set(
      {'isDarkTheme': isDarkTheme},
      SetOptions(merge: true),
    );
  }

  Future<bool> loadUserTheme() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['isDarkTheme'] ?? false;
  }
}

// -------- 30-day average helper --------

Future<Map<String, String>> get30DayAverageBedAndWakeTime({int days = 30}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {'averageBedtimeStr':'','averageWakeTimeStr':''};

  final snapshot = await FirebaseFirestore.instance
    .collection('sleep_logs')
    .where('userId', isEqualTo: user.uid)
    .orderBy('timestamp', descending: true)
    .limit(days)
    .get();

  if (snapshot.docs.isEmpty) return {'averageBedtimeStr':'','averageWakeTimeStr':''};

  int _toMinutes(String txt) {
    try {
      final dt = DateFormat.jm().parse(txt);
      return dt.hour * 60 + dt.minute;
    } catch (_) {
      try {
        final dt2 = DateTime.parse(txt);
        return dt2.hour * 60 + dt2.minute;
      } catch (_) {
        return 0;
      }
    }
  }

  final bedMinutes = <int>[], wakeMinutes = <int>[];
  for (var doc in snapshot.docs) {
    final d       = doc.data();
    final bedStr  = d['timeInBed']    as String? ?? '';
    final totMin  = d['totalMinutes'] as int?    ?? 0;
    final awMin   = d['awakeMinutes'] as int?    ?? 0;
    if (bedStr.isEmpty) continue;
    final bedMin = _toMinutes(bedStr);
    bedMinutes.add(bedMin);
    wakeMinutes.add((bedMin + totMin + awMin) % 1440);
  }

  int _circularMean(List<int> mins) {
    final rad = mins.map((m) => 2*pi*(m/1440));
    final x   = rad.map(cos).reduce((a,b)=>a+b)/rad.length;
    final y   = rad.map(sin).reduce((a,b)=>a+b)/rad.length;
    final ang = atan2(y, x);
    final norm= ang < 0 ? ang + 2*pi : ang;
    return (norm / (2*pi) * 1440).round();
  }

  final avgBedMin  = _circularMean(bedMinutes);
  final avgWakeMin = _circularMean(wakeMinutes);

  String _format(int minutes) {
    final h  = minutes ~/ 60;
    final m  = minutes % 60;
    final dt = DateTime(1970,1,1,h,m);
    return DateFormat.jm().format(dt);
  }

  return {
    'averageBedtimeStr': _format(avgBedMin),
    'averageWakeTimeStr': _format(avgWakeMin),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Magic Sleep Score Constants & Function
// ─────────────────────────────────────────────────────────────────────────────

const int    minSleepForScore      = 240;
const int    halfSleepMinutes      = 360;
const int    fullSleepMinutes      = 480;
const int    maxDurationPoints     = 22;
const int    bonusCapPoints        = 3;
const double bonusRatePerMinute    = 0.02;

const double effThresholdLow       = 0.75;
const double effThresholdMid       = 0.85;
const double effThresholdHigh      = 0.95;
const int    maxEfficiencyPoints   = 20;

const double deepThresholdLow      = 0.08;
const double deepThresholdMid      = 0.15;
const double deepThresholdHigh     = 0.22;
const int    maxDeepPoints         = 22;

const double remThresholdLow       = 0.12;
const double remThresholdMid       = 0.20;
const double remThresholdHigh      = 0.28;
const int    maxRemPoints          = 22;

const double maxLatencyPoints      = 6.0;
const int    latencyFast           = 15;
const int    latencySlow           = 30;

const int    consistencyCutoff     = 40;
const double maxConsistencyHalfPts = 4.0;

double _computeSleepScore({
  required int    totalMinutes,
  required int    deepMinutes,
  required int    remMinutes,
  required int    awakeMinutes,
  required String timeInBedStr,
  required String timeAsleepStr,
  required String timeAwakeStr,
  required String averageBedtimeStr,
  required String averageWakeTimeStr,
}) {
  if (totalMinutes <= 0) return 0.0;

  final inBedDT   = _safeParseTime(timeInBedStr);
  DateTime asleepDT = _safeParseTime(timeAsleepStr);
  if (asleepDT.isBefore(inBedDT)) asleepDT = asleepDT.add(Duration(days: 1));

  DateTime awakeDT = _safeParseTime(timeAwakeStr);
  if (awakeDT.isBefore(asleepDT)) awakeDT = awakeDT.add(Duration(days: 1));

  // 1) Duration
  double durationScore;
  if (totalMinutes <= minSleepForScore) {
    durationScore = 0.0;
  } else if (totalMinutes <= halfSleepMinutes) {
    durationScore = (totalMinutes - minSleepForScore) /
                    (halfSleepMinutes - minSleepForScore) * 10.0;
  } else if (totalMinutes <= fullSleepMinutes) {
    durationScore = 10.0 + (totalMinutes - halfSleepMinutes) /
                    (fullSleepMinutes - halfSleepMinutes) *
                    (maxDurationPoints - 10);
  } else {
    double bonus = (totalMinutes - fullSleepMinutes) * bonusRatePerMinute;
    if (bonus > bonusCapPoints) bonus = bonusCapPoints.toDouble();
    durationScore = maxDurationPoints.toDouble() + bonus;
  }

  // 2) Efficiency
  final totalTime = totalMinutes + awakeMinutes;
  final efficiency = totalTime > 0 ? totalMinutes / totalTime : 0.0;
  double efficiencyScore;
  if (efficiency <= effThresholdLow) {
    efficiencyScore = 0.0;
  } else if (efficiency <= effThresholdMid) {
    efficiencyScore = (efficiency - effThresholdLow) /
                      (effThresholdMid - effThresholdLow) *
                      (maxEfficiencyPoints / 2);
  } else if (efficiency <= effThresholdHigh) {
    efficiencyScore = (maxEfficiencyPoints / 2) +
                      (efficiency - effThresholdMid) /
                      (effThresholdHigh - effThresholdMid) *
                      (maxEfficiencyPoints / 2);
  } else {
    efficiencyScore = maxEfficiencyPoints.toDouble();
  }

  // 3) Deep %
  final deepPct = deepMinutes / totalMinutes;
  double deepScore;
  if (deepPct <= deepThresholdLow) {
    deepScore = 0.0;
  } else if (deepPct <= deepThresholdMid) {
    deepScore = (deepPct - deepThresholdLow) /
                (deepThresholdMid - deepThresholdLow) *
                (maxDeepPoints / 2);
  } else if (deepPct <= deepThresholdHigh) {
    deepScore = (maxDeepPoints / 2) +
                (deepPct - deepThresholdMid) /
                (deepThresholdHigh - deepThresholdMid) *
                (maxDeepPoints / 2);
  } else {
    deepScore = maxDeepPoints.toDouble();
  }

  // 4) REM %
  final remPct = remMinutes / totalMinutes;
  double remScore;
  if (remPct <= remThresholdLow) {
    remScore = 0.0;
  } else if (remPct <= remThresholdMid) {
    remScore = (remPct - remThresholdLow) /
               (remThresholdMid - remThresholdLow) *
               (maxRemPoints / 2);
  } else if (remPct <= remThresholdHigh) {
    remScore = (maxRemPoints / 2) +
               (remPct - remThresholdMid) /
               (remThresholdHigh - remThresholdMid) *
               (maxRemPoints / 2);
  } else {
    remScore = maxRemPoints.toDouble();
  }

  // 5) Latency
  final latency = asleepDT.difference(inBedDT).inMinutes.clamp(0, latencySlow);
  double latencyScore;
  if (latency <= latencyFast) {
    latencyScore = maxLatencyPoints;
  } else {
    latencyScore = ((latencySlow - latency) /
                    (latencySlow - latencyFast)) *
                    maxLatencyPoints;
  }

  // 6) Consistency
  final avgBedDT  = _safeParseTime(averageBedtimeStr);
  final avgWakeDT = _safeParseTime(averageWakeTimeStr);
  final bedDelta  = (inBedDT.difference(avgBedDT).inMinutes).abs();
  final wakeDelta = (awakeDT.difference(avgWakeDT).inMinutes).abs();

  double _subConsistency(int diff) {
    if (diff <= consistencyCutoff ~/ 2) {
      return maxConsistencyHalfPts;
    } else if (diff <= consistencyCutoff) {
      return (consistencyCutoff - diff) / (consistencyCutoff ~/ 2) *
             maxConsistencyHalfPts;
    } else {
      return 0.0;
    }
  }
  final consistencyScore =
      _subConsistency(bedDelta) + _subConsistency(wakeDelta);

  final raw = durationScore
            + efficiencyScore
            + deepScore
            + remScore
            + latencyScore
            + consistencyScore;

  return raw.clamp(0, 100).roundToDouble();
}
