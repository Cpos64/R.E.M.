import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sleep_log_service.dart';

class ViewSleepLogScreen extends StatefulWidget {
  final String docId;
  final String duration;
  final String quality;
  final DateTime timestamp;

  ViewSleepLogScreen({
    required this.docId,
    required this.duration,
    required this.quality,
    required this.timestamp,
  });

  @override
  _ViewSleepLogScreenState createState() => _ViewSleepLogScreenState();
}

class _ViewSleepLogScreenState extends State<ViewSleepLogScreen> {
  final SleepLogService _sleepLogService = SleepLogService();
  bool _isEditing = false;
  final TextEditingController _durationController = TextEditingController();
  String _quality = 'Good';

  @override
  void initState() {
    super.initState();
    _durationController.text = widget.duration;
    _quality = widget.quality;
  }

  Future<void> _saveSleepLog() async {
    await _sleepLogService.updateSleepLog(widget.docId, _durationController.text, _quality, DateTime.now());
    setState(() {
      _isEditing = false;
    });
    Navigator.of(context).pop(true); // Return to previous screen after editing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Sleep Log'),
        actions: _isEditing
            ? [
                IconButton(
                  icon: Icon(Icons.save),
                  onPressed: _saveSleepLog,
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
              ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${widget.timestamp.toLocal().toString().split(' ')[0]}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _durationController,
              decoration: InputDecoration(labelText: 'Duration (e.g., 6h35m)'),
              enabled: _isEditing,
            ),
            SizedBox(height: 10),
            if (_isEditing)
              DropdownButtonFormField<String>(
                value: _quality,
                items: ['Good', 'Average', 'Poor'].map((quality) {
                  return DropdownMenuItem(
                    value: quality,
                    child: Text(quality),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _quality = value!),
                decoration: InputDecoration(
                  labelText: 'Sleep Quality',
                  border: OutlineInputBorder(),
                ),
              )
            else
              Text('Quality: $_quality'),
          ],
        ),
      ),
    );
  }
}
