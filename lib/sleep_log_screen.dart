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
  String _quality = 'Good';

  void _saveSleepLog() async {
    final duration = int.tryParse(_durationController.text) ?? 0;

    if (duration > 0) {
      await _sleepLogService.saveSleepLog(duration, _quality, DateTime.now());
      _durationController.clear();
      setState(() {});
    }
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
                labelText: 'Sleep Duration (in minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _quality,
              items: ['Good', 'Average', 'Poor']
                  .map((quality) => DropdownMenuItem(
                        value: quality,
                        child: Text(quality),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _quality = value!),
              decoration: InputDecoration(
                labelText: 'Sleep Quality',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveSleepLog,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text('Save Sleep Log'),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _sleepLogService.getSleepLogs(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();

                  final sleepLogs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: sleepLogs.length,
                    itemBuilder: (context, index) {
                      final log = sleepLogs[index];
                      final date = (log['date'] as Timestamp).toDate();
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text('Duration: ${log['duration']} minutes'),
                          subtitle: Text(
                              'Quality: ${log['quality']} - Date: ${date.toLocal()}'),
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

