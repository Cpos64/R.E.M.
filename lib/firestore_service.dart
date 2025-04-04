import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveDream(String title, String description) async {
    final user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('dreams').add({
        'userId': user.uid,
        'title': title,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<QuerySnapshot> getDreams() {
    final user = _auth.currentUser;

    if (user != null) {
      return _firestore
          .collection('dreams')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();
    }

    return const Stream.empty();
  }
}
