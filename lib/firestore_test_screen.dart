import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';  // Ensure this is correctly imported if you have it

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(FirestoreTestApp());
}

class FirestoreTestApp extends StatelessWidget {
  const FirestoreTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Test',
      home: FirestoreTestScreen(),
    );
  }
}

class FirestoreTestScreen extends StatelessWidget {
  const FirestoreTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firestore Test')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('dreams').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No dreams found in Firestore.'));
          }

          final dreams = snapshot.data!.docs;

          return ListView.builder(
            itemCount: dreams.length,
            itemBuilder: (context, index) {
              final dream = dreams[index];
              final title = dream['title'] ?? 'No Title';
              final description = dream['description'] ?? 'No Description';

              return ListTile(
                title: Text(title),
                subtitle: Text(description),
              );
            },
          );
        },
      ),
    );
  }
}
