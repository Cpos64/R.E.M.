import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // ------------------ SLEEP LOG METHODS ------------------

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

  Future<void> saveSleepLog(String duration, String quality) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('sleep_logs').add({
      'duration': duration,
      'quality': quality,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': user.uid,
    });
  }

  Future<void> updateSleepLog(String docId, String newDuration, String newQuality) async {
    await _firestore.collection('sleep_logs').doc(docId).update({
      'duration': newDuration,
      'quality': newQuality,
    });
  }

  Future<void> deleteSleepLog(String docId) async {
    await _firestore.collection('sleep_logs').doc(docId).delete();
  }

    // -------- USER THEME PREFERENCES --------

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
