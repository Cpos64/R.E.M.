// lib/me_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import 'widgets/dream_chart_pager.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  final _service = FirestoreService();
  int _dreamCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final count = await _service.dreamCountForUser(uid);
    setState(() {
      _dreamCount = count;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Chart on top ──
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('dreams')
                            .where(
                              'userId',
                              isEqualTo:
                                  FirebaseAuth.instance.currentUser?.uid,
                            )
                            .snapshots(),
                        builder: (ctx, snap) {
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final docs = snap.data?.docs
                                  .cast<QueryDocumentSnapshot>() ??
                              <QueryDocumentSnapshot>[];

                          // group docs by calendar-day
                          final docsByDay =
                              <DateTime, List<QueryDocumentSnapshot>>{};
                          for (var doc in docs) {
                            final ts =
                                (doc['timestamp'] as Timestamp).toDate();
                            final day =
                                DateTime(ts.year, ts.month, ts.day);
                            docsByDay.putIfAbsent(day, () => []).add(doc);
                          }

                          // build buckets list
                          final buckets = docsByDay.entries.map((e) {
                            return {
                              'date': e.key,
                              'totalCount': e.value.length,
                            };
                          }).toList();

                          return DreamChartPager(buckets: buckets);
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Total count below ──
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Dreams Logged',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_dreamCount',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
