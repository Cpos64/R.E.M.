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
      print("✅ Dream Saved Successfully: $title");
    } else {
      print("❌ Error: User is not authenticated.");
    }
  }

  Future<void> updateDream(String docId, String title, String description) async {
    await _firestore.collection('dreams').doc(docId).update({
      'title': title,
      'description': description,
    });
    print("✅ Dream Updated: $title");
  }

  Future<void> deleteDream(String docId) async {
    await _firestore.collection('dreams').doc(docId).delete();
    print("✅ Dream Deleted: $docId");
  }

Future<List<QueryDocumentSnapshot>> getDreams() async {
  final user = _auth.currentUser;

  if (user != null) {
    print("🔍 Fetching dreams for user: ${user.uid}");

    try {
      final snapshot = await _firestore
          .collection('dreams')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      print("✅ Retrieved ${snapshot.docs.length} dreams from Firestore.");
      
      if (snapshot.docs.isEmpty) {
        print("❌ No dreams found in the Firestore database for this user.");
      }

      for (var doc in snapshot.docs) {
        print("📄 Dream: ${doc['title']} - ${doc['description']} - Timestamp: ${doc['timestamp']}");
      }

      return snapshot.docs;
    } catch (e) {
      print("❌ Error fetching dreams: $e");
      return [];
    }
  }
  print("❌ Error: User is not authenticated.");
  return [];
}
}
