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
      "timestamp": Timestamp.now(),
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
    "timestamp": Timestamp.now(),
    "userId": user.uid,
  };

  print('Saving sleep log (auto) for userId: ${user.uid}');
  print('Data: $data');

  await _firestore.collection('sleep_logs').add(data);
}

double _computeSleepScore({
  required int totalMinutes,
  required int deepMinutes,
  required int remMinutes,
  required int awakeMinutes,
}) {
  if (totalMinutes == 0) return 0;

  final deepPct = deepMinutes / totalMinutes;
  final remPct = remMinutes / totalMinutes;
  final awakePct = awakeMinutes / totalMinutes;

  double score = 0;

  // Total duration score
  if (totalMinutes >= 420 && totalMinutes <= 540) {
    score += 30;
  } else if (totalMinutes >= 360) {
    score += 20;
  } else {
    score += 10;
  }

  // Deep sleep score
  if (deepPct >= 0.13 && deepPct <= 0.23) {
    score += 25;
  } else if (deepPct >= 0.10 && deepPct <= 0.25) {
    score += 15;
  } else {
    score += 5;
  }

  // REM sleep score
  if (remPct >= 0.20 && remPct <= 0.25) {
    score += 25;
  } else if (remPct >= 0.15 && remPct <= 0.30) {
    score += 15;
  } else {
    score += 5;
  }

  // Awake time penalty
  if (awakePct < 0.05) {
    score += 20;
  } else if (awakePct < 0.10) {
    score += 10;
  }

  return score.clamp(0, 100).roundToDouble();
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
