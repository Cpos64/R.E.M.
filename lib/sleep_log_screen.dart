import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sleep_log_service.dart';

class SleepLogScreen extends StatefulWidget {
  @override
  _SleepLogScreenState createState() => _SleepLogScreenState();
}

class _SleepLogScreenState extends State<SleepLogScreen> {
  final SleepLogService _sleepLogService = SleepLogService();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _editDurationController = TextEditingController();
  final TextEditingController _editQualityController = TextEditingController();
  String _quality = 'Good';

  late Future<List<QueryDocumentSnapshot>> _sleepLogsFuture;

  @override
  void initState() {
    super.initState();
    _sleepLogsFuture = _loadSleepLogs();
  }

  Future<List<QueryDocumentSnapshot>> _loadSleepLogs() async {
    return await _sleepLogService.getSleepLogs();
  }

  Future<void> _saveSleepLog() async {
    final durationText = _durationController.text.trim();

    final regex = RegExp(r'^\d{1,2}h\d{1,2}m$');
    if (!regex.hasMatch(durationText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid duration format. Use _h_m (e.g., 6h35m).')),
      );
      return;
    }

    await _sleepLogService.saveSleepLog(durationText, _quality, DateTime.now());
    _durationController.clear();

    setState(() {
      _sleepLogsFuture = _loadSleepLogs();
    });
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
              decoration: InputDecoration(labelText: 'Duration (e.g., 6h35m)'),
            ),
            TextField(
              controller: _editQualityController,
              decoration: InputDecoration(labelText: 'Quality (Good, Average, Poor)'),
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

              await _sleepLogService.updateSleepLog(docId, newDuration, newQuality);
              Navigator.of(context).pop();
              setState(() {
                _sleepLogsFuture = _loadSleepLogs();
              });
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSleepLog(String docId) async {
    await _sleepLogService.deleteSleepLog(docId);
    setState(() {
      _sleepLogsFuture = _loadSleepLogs();
    });
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
                labelText: 'Sleep Duration (e.g., 6h35m)',
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
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No sleep logs saved yet.'));
                  }

                  final sleepLogs = snapshot.data!;

                  return ListView.builder(
                    itemCount: sleepLogs.length,
                    itemBuilder: (context, index) {
                      final log = sleepLogs[index];
                      final docId = log.id;
                      final duration = log['duration'];
                      final quality = log['quality'];
                      final date = (log['date'] as Timestamp).toDate();

                      return Card(
                        child: ListTile(
                          title: Text('Duration: $duration'),
                          subtitle: Text('Quality: $quality - Date: ${date.toLocal().toString().split(' ')[0]}'),
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
