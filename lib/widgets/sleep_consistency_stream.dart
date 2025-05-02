import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'sleep_consistency_chart.dart';  // already updated chart class

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
          return Center(child: Text('Error: \${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No sleep data yet.'));
        }

        // Chronological order: oldest first
        final ordered = docs.reversed.toList();

        // Build the days list
        final days = ordered
            .map((doc) => (doc.data()['timestamp'] as Timestamp).toDate())
            .toList();

        // Build buckets matching SleepConsistencyChart's expected format
        final buckets = ordered.map((doc) {
          final data = doc.data();
          return <String, dynamic>{
            'timeInBed': data['timeInBed'] ?? '',
            'timeAsleep': data['timeAsleep'] ?? '',
            'timeAwake': data['timeAwake'] ?? '',
          };
        }).toList();

        return SleepConsistencyChart(
          buckets: buckets,
          days: days,
        );
      },
    );
  }
}

// Legend dot unchanged
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}