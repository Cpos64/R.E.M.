import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'sleep_consistency_chart.dart';  // ← import your chart class

class SleepConsistencyStream extends StatelessWidget {
  const SleepConsistencyStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to see your sleep data.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('sleep_logs')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(7)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Map each Firestore doc into the shape your chart expects:
        final docs = snapshot.data!.docs;
        final sleepData = docs.map((doc) {
          final data = doc.data();
          return {
            'date':       (data['timestamp'] as Timestamp).toDate(),
            'timeInBed':  data['timeInBed']  ?? '',
            'timeAsleep': data['timeAsleep'] ?? '',
            'timeAwake':  data['timeAwake']  ?? '',
          };
        }).toList().reversed.toList(); // oldest → newest

        // Feed it into your chart:
        return SleepConsistencyChart(sleepData: sleepData);
      },
    );
  }
}
