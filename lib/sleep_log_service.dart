import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SleepLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveSleepLog(int duration, String quality, DateTime date) async {
    final user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('sleep_logs').add({
        'userId': user.uid,
        'duration': duration,  // Sleep duration in minutes
        'quality': quality,  // Sleep quality (e.g., "Good", "Average", "Poor")
        'date': date,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<QuerySnapshot> getSleepLogs() {
    final user = _auth.currentUser;

    if (user != null) {
      return _firestore
          .collection('sleep_logs')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();
    }

    return const Stream.empty();
  }
}
