import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final data = doc.data() as Map<String, dynamic>;
    return {
      'date': (data['timestamp'] as Timestamp).toDate(),
      'totalSleep': data['totalDuration'] ?? 0,
      'deepSleep': data['deepSleep'] ?? 0,
      'remSleep': data['remSleep'] ?? 0,
      'awakeTime': data['awakeTime'] ?? 0,
    };
  }).toList().reversed.toList(); // oldest to newest
}


  Future<void> saveSleepLog({
    required String totalDuration,
    required String deepSleep,
    required String remSleep,
    required String awakeTime,
    required String quality,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final data = {
      "totalDuration": totalDuration,
      "deepSleep": deepSleep,
      "remSleep": remSleep,
      "awakeTime": awakeTime,
      "quality": quality,
      "notes": notes ?? "",
      "timestamp": Timestamp.now(),
      "userId": user.uid,
    };

    print('Saving sleep log for userId: ${user.uid}');
    print('Data: $data');

    await _firestore.collection('sleep_logs').add(data);
  }

  Future<void> updateSleepLog(
    String docId,
    String totalDuration,
    String deepSleep,
    String remSleep,
    String awakeTime,
    String quality,
    String? notes,
  ) async {
    await _firestore.collection('sleep_logs').doc(docId).update({
      "totalDuration": totalDuration,
      "deepSleep": deepSleep,
      "remSleep": remSleep,
      "awakeTime": awakeTime,
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
