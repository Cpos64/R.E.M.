import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Streams your dreams and builds a PieChart of genres.
class DreamGenrePieChart extends StatelessWidget {
  const DreamGenrePieChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dreams')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        final docs = snap.data!.docs;
        // 1) tally genres
        final counts = <String,int>{};
        for (var doc in docs) {
          final g = (doc['genre'] as String?) ?? 'Other';
          counts[g] = (counts[g] ?? 0) + 1;
        }
        if (counts.isEmpty) {
          return const SizedBox(height: 200, child: Center(child: Text('No dreams yet.')));
        }
        // 2) build PieChart sections
        final sections = <PieChartSectionData>[];
        final total = docs.length.toDouble();
        var i = 0;
        for (var entry in counts.entries) {
          final color = Colors.primaries[i++ % Colors.primaries.length].shade400;
          sections.add(PieChartSectionData(
            title: '${entry.value}',
            value: entry.value.toDouble(),
            color: color,
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ));
        }

        return SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 30,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        );
      },
    );
  }
}
