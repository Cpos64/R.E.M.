import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:rem/widgets/sleep_entry_card.dart';

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
  final ScrollController _scrollController = ScrollController();

  late Future<List<QueryDocumentSnapshot>> _sleepLogsFuture;
  bool _isFirstLoad = true;

  bool isValidDurationFormat(String input) {
  final regex = RegExp(r'^(\d+h)?(\d+m)?$');
  return regex.hasMatch(input.trim());
}


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

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

void _showAddSleepDialog() {
  _durationController.clear();
  _qualityController.clear();

  // Add controllers for the new fields
  final TextEditingController deepController = TextEditingController();
  final TextEditingController remController = TextEditingController();
  final TextEditingController awakeController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _durationController,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Total Duration (e.g. 7h30m)'),
          ),
          SizedBox(height: 10),
          TextField(
            controller: deepController,
            decoration: InputDecoration(labelText: 'Deep Sleep (e.g. 1h30m)'),
          ),
          SizedBox(height: 10),
          TextField(
            controller: remController,
            decoration: InputDecoration(labelText: 'REM Sleep (e.g. 1h15m)'),
          ),
          SizedBox(height: 10),
          TextField(
            controller: awakeController,
            decoration: InputDecoration(labelText: 'Awake Time (e.g. 0h45m)'),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _qualityController,
            decoration: InputDecoration(labelText: 'Quality (e.g. Restful)'),
          ),
          SizedBox(height: 10),
          TextField(
            controller: notesController,
            decoration: InputDecoration(labelText: 'Notes (optional)'),
            maxLines: 3,
          ),
                    SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final total = _durationController.text.trim();
              final deep = deepController.text.trim();
              final rem = remController.text.trim();
              final awake = awakeController.text.trim();
              final quality = _qualityController.text.trim();
              final notes = notesController.text.trim();

              if (!isValidDurationFormat(total) ||
                  !isValidDurationFormat(deep) ||
                  !isValidDurationFormat(rem) ||
                  !isValidDurationFormat(awake)) {
                print('Invalid format');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please use format like 6h45m or 30m')),
                );
                return;
              }

              try {
                print('Attempting to save sleep log...');
                await _firestoreService.saveSleepLog(
                  totalDuration: total,
                  deepSleep: deep,
                  remSleep: rem,
                  awakeTime: awake,
                  quality: quality,
                  notes: notes,
                );
                print('Sleep log saved successfully!');
              } catch (e) {
                print('Error while saving sleep log: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error saving log: $e')),
                );
                return;
              }

              _loadSleepLogs(); // ✅ refresh list immediately
              Navigator.of(context).pop();
              _scrollToBottom();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sleep log saved!')),
              );

            },
            child: Text('Save Sleep Log'),
          ),
        ],
      ),
    ),
  );
}


Future<void> _editSleepLog(
  String docId,
  String currentTotal,
  String currentDeep,
  String currentRem,
  String currentAwake,
  String currentQuality,
  String? currentNotes,
) async {
  final TextEditingController _editTotalController = TextEditingController(text: currentTotal);
  final TextEditingController _editDeepController = TextEditingController(text: currentDeep);
  final TextEditingController _editRemController = TextEditingController(text: currentRem);
  final TextEditingController _editAwakeController = TextEditingController(text: currentAwake);
  final TextEditingController _editQualityController = TextEditingController(text: currentQuality);
  final TextEditingController _editNotesController = TextEditingController(text: currentNotes ?? "");

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Edit Sleep Log'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _editTotalController, decoration: InputDecoration(labelText: 'Total Duration')),
            TextField(controller: _editDeepController, decoration: InputDecoration(labelText: 'Deep Sleep')),
            TextField(controller: _editRemController, decoration: InputDecoration(labelText: 'REM Sleep')),
            TextField(controller: _editAwakeController, decoration: InputDecoration(labelText: 'Awake Time')),
            TextField(controller: _editQualityController, decoration: InputDecoration(labelText: 'Quality')),
            TextField(controller: _editNotesController, decoration: InputDecoration(labelText: 'Notes'), maxLines: 3),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await _firestoreService.updateSleepLog(
              docId,
              _editTotalController.text.trim(),
              _editDeepController.text.trim(),
              _editRemController.text.trim(),
              _editAwakeController.text.trim(),
              _editQualityController.text.trim(),
              _editNotesController.text.trim(),
            );
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSleepDialog,
        child: Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                    controller: _scrollController,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final docId = log.id;
                      final data = log.data() as Map<String, dynamic>;
                      final duration = data.containsKey('totalDuration')
                          ? data['totalDuration']
                          : data['duration'] ?? 'Unknown';

                      final quality = log['quality'] ?? 'Unknown';

                      final timestamp = (log.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      final formattedDate = timestamp != null
                          ? DateFormat.yMMMd().format(timestamp.toDate())
                          : 'No Date';

                      return SleepEntryCard(
                        duration: duration,
                        quality: quality,
                        date: formattedDate,
                        onEdit: () => _editSleepLog(
                        docId,
                        data.containsKey('totalDuration') ? data['totalDuration'] : data['duration'] ?? '',
                        data['deepSleep'] ?? '',
                        data['remSleep'] ?? '',
                        data['awakeTime'] ?? '',
                        data['quality'] ?? '',
                        data['notes'] ?? '',
                      ),

                        onDelete: () => _deleteSleepLog(docId),
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
