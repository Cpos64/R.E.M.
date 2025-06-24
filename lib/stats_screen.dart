import 'package:flutter/material.dart';
import 'firestore_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  double _avgMinutes = 0;
  int _dreamCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _firestoreService.getCurrentWeekStats();
    setState(() {
      _avgMinutes = (stats['avgMinutes'] as num?)?.toDouble() ?? 0;
      _dreamCount = stats['dreamCount'] as int? ?? 0;
      _loading = false;
    });
  }

  String _format(double minutes) {
    if (minutes <= 0) return '---';
    final min = minutes.round();
    final h = min ~/ 60;
    final m = min % 60;
    return '${h}h${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Average Sleep: ${_format(_avgMinutes)}'),
                  const SizedBox(height: 8),
                  Text('Dreams this Week: $_dreamCount'),
                ],
              ),
            ),
    );
  }
}
