import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SleepLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveSleepLog(String duration, String quality, DateTime date) async {
    final user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('sleep_logs').add({
        'userId': user.uid,
        'duration': duration,
        'quality': quality,
        'date': date,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("✅ Sleep Log Saved Successfully: $duration, $quality, $date");
    } else {
      print("❌ Error: User is not authenticated.");
    }
  }

  Future<void> updateSleepLog(String docId, String duration, String quality) async {
    await _firestore.collection('sleep_logs').doc(docId).update({
      'duration': duration,
      'quality': quality,
    });
    print("✅ Sleep Log Updated: $duration, $quality");
  }

  Future<void> deleteSleepLog(String docId) async {
    await _firestore.collection('sleep_logs').doc(docId).delete();
    print("✅ Sleep Log Deleted: $docId");
  }

  Future<List<QueryDocumentSnapshot>> getSleepLogs() async {
    final user = _auth.currentUser;

    if (user != null) {
      final snapshot = await _firestore
          .collection('sleep_logs')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs;
    }
    return [];
  }
}
