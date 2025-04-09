import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import 'package:intl/intl.dart';

class SleepLogScreen extends StatefulWidget {
  const SleepLogScreen({super.key});

  @override
  _SleepLogScreenState createState() => _SleepLogScreenState();
}

class _SleepLogScreenState extends State<SleepLogScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _qualityController = TextEditingController();
  final TextEditingController _editDurationController = TextEditingController();
  final TextEditingController _editQualityController = TextEditingController();

  late Future<List<QueryDocumentSnapshot>> _sleepLogsFuture;
  bool _isFirstLoad = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      _loadSleepLogs();
      _isFirstLoad = false;
    }
  }

  void _loadSleepLogs() {
    setState(() {
      _sleepLogsFuture = _firestoreService.getSleepLogs();
    });
  }

  Future<void> _saveSleepLog() async {
    final duration = _durationController.text.trim();
    final quality = _qualityController.text.trim();

    if (duration.isNotEmpty && quality.isNotEmpty) {
      await _firestoreService.saveSleepLog(duration, quality);
      _durationController.clear();
      _qualityController.clear();
      _loadSleepLogs();
    }
  }

  Future<void> _editSleepLog(String docId, String currentDuration, String currentQuality) async {
    _editDurationController.text = currentDuration;
    _editQualityController.text = currentQuality;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Sleep Log'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _editDurationController,
              decoration: InputDecoration(labelText: 'Duration (e.g. 7h30m)'),
            ),
            TextField(
              controller: _editQualityController,
              decoration: InputDecoration(labelText: 'Quality (e.g. Good)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newDuration = _editDurationController.text.trim();
              final newQuality = _editQualityController.text.trim();
              await _firestoreService.updateSleepLog(docId, newDuration, newQuality);
              Navigator.of(context).pop();
              _loadSleepLogs();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSleepLog(String docId) async {
    await _firestoreService.deleteSleepLog(docId);
    _loadSleepLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sleep Log')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _durationController,
              decoration: InputDecoration(
                labelText: 'Duration (e.g. 6h45m)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _qualityController,
              decoration: InputDecoration(
                labelText: 'Quality (e.g. Restless, Good)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveSleepLog,
              child: Text('Save Sleep Log'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: _sleepLogsFuture,
                builder: (context, snapshot) {
                  print('Sleep logs snapshot: ${snapshot.connectionState}');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No sleep logs saved yet.'));
                  }

                  final logs = snapshot.data!;
                  print('Loaded ${logs.length} sleep logs');

                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final docId = log.id;
                      final duration = log['duration'];
                      final quality = log['quality'];
                      final timestamp = (log.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      final formattedDate = timestamp != null
                          ? DateFormat.yMMMd().format(timestamp.toDate())
                          : 'No Date';

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text('$formattedDate - $duration'),
                          subtitle: Text('Quality: $quality'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _editSleepLog(docId, duration, quality),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteSleepLog(docId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
