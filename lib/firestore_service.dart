import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // ------------------ DREAM METHODS ------------------

Future<List<QueryDocumentSnapshot>> getDreams() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('dreams')
      .get(); // <-- no orderBy
  return snapshot.docs;
}

  Future<void> saveDream(String title, String description) async {
    await FirebaseFirestore.instance.collection('dreams').add({
      'title': title,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDream(String docId, String newTitle, String newDescription) async {
    await FirebaseFirestore.instance.collection('dreams').doc(docId).update({
      'title': newTitle,
      'description': newDescription,
    });
  }

  Future<void> deleteDream(String docId) async {
    await FirebaseFirestore.instance.collection('dreams').doc(docId).delete();
  }

  // ------------------ SLEEP LOG METHODS ------------------

Future<List<QueryDocumentSnapshot>> getSleepLogs() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('sleepLogs')
      .get(); // <-- no orderBy
  return snapshot.docs;
}

  Future<void> saveSleepLog(String duration, String quality) async {
    await FirebaseFirestore.instance.collection('sleepLogs').add({
      'duration': duration,
      'quality': quality,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSleepLog(String docId, String newDuration, String newQuality) async {
    await FirebaseFirestore.instance.collection('sleepLogs').doc(docId).update({
      'duration': newDuration,
      'quality': newQuality,
    });
  }

  Future<void> deleteSleepLog(String docId) async {
    await FirebaseFirestore.instance.collection('sleepLogs').doc(docId).delete();
  }
}
