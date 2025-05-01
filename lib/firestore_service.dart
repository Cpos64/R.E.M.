import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    final snapshot = await FirebaseFirestore.instance
        .collection('sleep_logs')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs;
  }

  Future<List<Map<String, dynamic>>> getLast7SleepLogsForChart() async {
    final user = FirebaseAuth.instance.currentUser;
    final snapshot = await FirebaseFirestore.instance
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

  Future<void> saveSleepLog({
    required String totalDuration,
    required String deepSleep,
    required String remSleep,
    required String lightSleep,
    required String awakeTime,
    required int sleepScore,
    required String timeAsleep,
    required String timeAwake,
    required String quality,
    String? notes,
    required DateTime date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final data = {
      "totalDuration": totalDuration,
      "deepSleep": deepSleep,
      "remSleep": remSleep,
      "lightSleep": lightSleep,
      "awakeTime": awakeTime,
      "sleepScore": sleepScore,
      "timeAsleep": timeAsleep,
      "timeAwake": timeAwake,
      "quality": quality,
      "notes": notes ?? "",
      "timestamp": Timestamp.fromDate(date),
      "userId": user.uid,
    };

    print('Saving sleep log for userId: \${user.uid}');
    print('Data: \$data');

    await _firestore.collection('sleep_logs').add(data);
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

  double parseToMinutes(String input) {
    final hours = RegExp(r'(\d+)h').firstMatch(input)?.group(1);
    final minutes = RegExp(r'(\d+)m').firstMatch(input)?.group(1);
    return (int.tryParse(hours ?? '0') ?? 0) * 60 + (int.tryParse(minutes ?? '0') ?? 0).toDouble();
  }

  final total = parseToMinutes(totalDuration);
  final deep = parseToMinutes(deepSleep);
  final rem = parseToMinutes(remSleep);
  final awake = parseToMinutes(awakeTime);
  final light = (total - (deep + rem + awake)).clamp(0, total);

  final sleepScore = _computeSleepScore(
    totalMinutes: total.toInt(),
    deepMinutes: deep.toInt(),
    remMinutes: rem.toInt(),
    awakeMinutes: awake.toInt(),
    timeInBedStr: timeInBed,
    timeAsleepStr: timeAsleep,
  );

  final lightStr = '${(light ~/ 60)}h${(light % 60).round()}m';

DateTime parsedTimeInBed = DateFormat.jm().parse(timeInBed);
DateTime parsedTimeAsleep = DateFormat.jm().parse(timeAsleep);
DateTime parsedTimeAwake = DateFormat.jm().parse(timeAwake);

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
    "timeInBed": parsedTimeInBed.toIso8601String(),
    "timeToFallAsleep": timeToFallAsleepReadable,
    "timeToFallAsleepISO": timeToFallAsleepISO,
    "quality": quality,
    "notes": notes ?? "",
    "timestamp": Timestamp.fromDate(date),
    "userId": user.uid,
  };

  print('Saving sleep log (auto) for userId: ${user.uid}');
  print('Data: $data');

  await _firestore.collection('sleep_logs').add(data);
}

/// Computes a 0–100 sleep score from raw minutes and times.
double _computeSleepScore({
  required int totalMinutes,
  required int deepMinutes,
  required int remMinutes,
  required int awakeMinutes,
  required String timeInBedStr,   // e.g. “10:30 PM”
  required String timeAsleepStr,  // e.g. “10:50 PM”
}) {
  if (totalMinutes <= 0) return 0;

  // ── Helper to parse "h:mm a" into a DateTime on today ──
  DateTime _parseTime(String txt) {
    final now = DateTime.now();
    final dt = DateFormat.jm().parse(txt);
    return DateTime(now.year, now.month, now.day, dt.hour, dt.minute);
  }

  // 1) Duration Score (0–20)
  //    <6h = 0, 6–7h → 0–10, 7–9h →10–20, >9h=20
  double durationScore;
  if (totalMinutes <= 360) {
    durationScore = 0;
  } else if (totalMinutes <= 420) {
    durationScore = (totalMinutes - 360) / 60 * 10;
  } else if (totalMinutes <= 540) {
    durationScore = 10 + (totalMinutes - 420) / 120 * 10;
  } else {
    durationScore = 20;
  }

  // 2) Sleep Efficiency Score (0–20)
  //    efficiency = sleepTime / (sleepTime + awakeTime)
  final efficiency = totalMinutes / (totalMinutes + awakeMinutes);
  double efficiencyScore;
  if (efficiency <= 0.75) {
    efficiencyScore = 0;
  } else if (efficiency <= 0.85) {
    efficiencyScore = (efficiency - 0.75) / 0.10 * 10;
  } else if (efficiency <= 0.95) {
    efficiencyScore = 10 + (efficiency - 0.85) / 0.10 * 10;
  } else {
    efficiencyScore = 20;
  }

  // 3) Deep-sleep % Score (0–20) – ideal 15–20%
  final deepPct = deepMinutes / totalMinutes;
  double deepScore;
  if (deepPct <= 0.10) {
    deepScore = 0;
  } else if (deepPct <= 0.15) {
    deepScore = (deepPct - 0.10) / 0.05 * 10;
  } else if (deepPct <= 0.20) {
    deepScore = 10 + (deepPct - 0.15) / 0.05 * 10;
  } else {
    deepScore = 20;
  }

  // 4) REM % Score (0–20) – ideal 20–25%
  final remPct = remMinutes / totalMinutes;
  double remScore;
  if (remPct <= 0.15) {
    remScore = 0;
  } else if (remPct <= 0.20) {
    remScore = (remPct - 0.15) / 0.05 * 10;
  } else if (remPct <= 0.25) {
    remScore = 10 + (remPct - 0.20) / 0.05 * 10;
  } else {
    remScore = 20;
  }

  // 5) Awake-time Penalty (0–10) – less awake is better
  //    <3% awake →10, 3–7% → 10→0 linear, >7%→0
  final awakePct = awakeMinutes / totalMinutes;
  double awakeScore;
  if (awakePct < 0.03) {
    awakeScore = 10;
  } else if (awakePct <= 0.07) {
    awakeScore = (0.07 - awakePct) / 0.04 * 10;
  } else {
    awakeScore = 0;
  }

  // 6) Sleep-Onset Latency (0–10) – faster to sleep is better
  final inBed   = _parseTime(timeInBedStr);
  final asleep  = _parseTime(timeAsleepStr);
  final latency = asleep.difference(inBed).inMinutes.clamp(0, 60);
  double latencyScore;
  if (latency <= 15) {
    latencyScore = 10;
  } else if (latency <= 30) {
    latencyScore = (30 - latency) / 15 * 5; // 15–30 → 5→0
  } else {
    latencyScore = 0;
  }

  // ── Sum & clamp ──
  final raw = durationScore
            + efficiencyScore
            + deepScore
            + remScore
            + awakeScore
            + latencyScore;

  return raw.clamp(0, 100).roundToDouble();
}


  Future<void> updateSleepLog(
    String docId,
    String totalDuration,
    String deepSleep,
    String remSleep,
    String lightSleep,
    String awakeTime,
    int sleepScore,
    String timeAsleep,
    String timeAwake,
    String quality,
    String? notes,
  ) async {
    await _firestore.collection('sleep_logs').doc(docId).update({
      "totalDuration": totalDuration,
      "deepSleep": deepSleep,
      "remSleep": remSleep,
      "lightSleep": lightSleep,
      "awakeTime": awakeTime,
      "sleepScore": sleepScore,
      "timeAsleep": timeAsleep,
      "timeAwake": timeAwake,
      "quality": quality,
      "notes": notes ?? "",
    });
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
