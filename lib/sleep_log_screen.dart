import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'firestore_service.dart';
import 'widgets/sleep_score_chart.dart';
import 'widgets/sleep_chart_pager.dart';
import 'widgets/sleep_entry_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Converts a "XhYm" string into total minutes.
int _parseToMinutes(String input) {
  final hours = int.tryParse(RegExp(r'(\d+)h').firstMatch(input)?.group(1) ?? '0') ?? 0;
  final mins  = int.tryParse(RegExp(r'(\d+)m').firstMatch(input)?.group(1) ?? '0') ?? 0;
  return hours * 60 + mins;
}


class SleepLogScreen extends StatefulWidget {
  const SleepLogScreen({super.key});

  @override
  _SleepLogScreenState createState() => _SleepLogScreenState();
}

class SleepInputField {
  final String label;
  final TextEditingController controller;
  final bool isDuration; // true = use timer picker, false = use time picker

  SleepInputField({
    required this.label,
    required this.controller,
    required this.isDuration,
  });
}

class _SleepLogScreenState extends State<SleepLogScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<QueryDocumentSnapshot>> _sleepLogsFuture;
  bool _isFirstLoad = true;
  int _selectedWindow = 7;

  final _durationController = TextEditingController();
  final _deepController = TextEditingController();
  final _remController = TextEditingController();
  final _awakeController = TextEditingController();
  final _asleepController = TextEditingController();
  final _wakeController = TextEditingController();
  final _qualityController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController     = TextEditingController(
    text: DateFormat.yMd().format(DateTime.now()),
);
  final _inBedController = TextEditingController();


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
  _loadSleepLogs();
  _isFirstLoad = false;
}
  }

    @override
  void dispose() {
    _durationController.dispose();
    _deepController.dispose();
    _remController.dispose();
    _awakeController.dispose();
    _asleepController.dispose();
    _wakeController.dispose();
    _qualityController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _inBedController.dispose();
    super.dispose();
  }


  void _loadSleepLogs() {
    setState(() {
      _sleepLogsFuture = _firestoreService.getSleepLogs();
    });
  }


  void _navigateToInput(List<SleepInputField> inputs, int index) {
  final input = inputs[index];
  input.isDuration
    ? _showUnifiedPicker(inputs: inputs, currentIndex: index)
    : _showUnifiedTimePicker(inputs: inputs, currentIndex: index);
}


Future<void> _showUnifiedPicker({
  required List<SleepInputField> inputs,
  required int currentIndex,
}) async {
  final input = inputs[currentIndex];
  final controller = input.controller;
  final initialValue = controller.text;
  final minutes = _parseToMinutes(initialValue);
  Duration selected = Duration(minutes: minutes);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).dialogBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    input.label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: selected,
                      onTimerDurationChanged: (duration) {
                        selected = duration;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: currentIndex > 0
                            ? () {
                                Navigator.pop(context);
                                final previous = inputs[currentIndex - 1];
                                previous.isDuration
                                    ? _showUnifiedPicker(inputs: inputs, currentIndex: currentIndex - 1)
                                    : _showUnifiedTimePicker(inputs: inputs, currentIndex: currentIndex - 1);
                              }
                            : null,
                        child: const Text('Back'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final h = selected.inHours;
                          final m = selected.inMinutes % 60;
                          controller.text = '${h}h${m}m';
                          Navigator.pop(context);
                        },
                        child: const Text('Done'),
                      ),
                      TextButton(
                        onPressed: currentIndex < inputs.length - 1
                            ? () {
                                final h = selected.inHours;
                                final m = selected.inMinutes % 60;
                                controller.text = '${h}h${m}m';
                                Navigator.pop(context);
                                _navigateToInput(inputs, currentIndex + 1);

                              }
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _showUnifiedTimePicker({
  required List<SleepInputField> inputs,
  required int currentIndex,
}) async {
  final input = inputs[currentIndex];
  final controller = input.controller;

  TimeOfDay initial = TimeOfDay.now();
  try {
    final parsed = TimeOfDay(
      hour: int.parse(RegExp(r'(\d+):').firstMatch(controller.text)?.group(1) ?? '0'),
      minute: int.parse(RegExp(r':(\d+)').firstMatch(controller.text)?.group(1) ?? '0'),
    );
    initial = parsed;
  } catch (_) {}

  DateTime now = DateTime.now();
  DateTime selected = DateTime(now.year, now.month, now.day, initial.hour, initial.minute);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).dialogBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    input.label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: selected,
                      use24hFormat: false,
                      onDateTimeChanged: (DateTime newTime) {
                        selected = newTime;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: currentIndex > 0
                            ? () {
                                Navigator.pop(context);
                                final previous = inputs[currentIndex - 1];
                                previous.isDuration
                                    ? _showUnifiedPicker(inputs: inputs, currentIndex: currentIndex - 1)
                                    : _showUnifiedTimePicker(inputs: inputs, currentIndex: currentIndex - 1);
                              }
                            : null,
                        child: const Text('Back'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final formatted = DateFormat.jm().format(selected);
                          controller.text = formatted;
                          Navigator.pop(context);
                        },
                        child: const Text('Done'),
                      ),
                      TextButton(
                        onPressed: currentIndex < inputs.length - 1
                            ? () {
                                final formatted = DateFormat.jm().format(selected);
                                controller.text = formatted;
                                Navigator.pop(context);
                                _navigateToInput(inputs, currentIndex + 1);

                              }
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void _showAddSleepDialog() {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Sleep Log'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _buildSleepFormContent(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            try {
              // parse the selected date
              final parsedDate = DateFormat.yMd().parse(_dateController.text.trim());

              await _firestoreService.saveSleepLogAuto(
                totalDuration: _durationController.text.trim(),
                deepSleep:     _deepController.text.trim(),
                remSleep:      _remController.text.trim(),
                awakeTime:     _awakeController.text.trim(),
                timeInBed:     _inBedController.text.trim(),
                timeAsleep:    _asleepController.text.trim(),
                timeAwake:     _wakeController.text.trim(),
                quality:       _qualityController.text.trim(),
                notes:         _notesController.text.trim(),
                date:          parsedDate,            // <-- new!
              );

              // clear everything
              _dateController.text     = DateFormat.yMd().format(DateTime.now());
              _durationController.clear();
              _deepController.clear();
              _remController.clear();
              _awakeController.clear();
              _inBedController.clear();
              _asleepController.clear();
              _wakeController.clear();
              _qualityController.clear();
              _notesController.clear();

              Navigator.of(ctx).pop();
              _loadSleepLogs();
            } catch (e, st) {
              // Log to console for debugging
              print('❌ Error saving sleep log: $e');
              print(st);

              // Show a user‐friendly SnackBar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving sleep log: $e')),
              );
            }
          },
          child: const Text('Save Sleep Log'),
        ),
      ],
    ),
  );
}

Widget _buildSleepFormContent() {
  // your existing duration/time fields
  final inputs = <SleepInputField>[
    SleepInputField(label: 'Total Duration',   controller: _durationController, isDuration: true),
    SleepInputField(label: 'Deep Sleep',       controller: _deepController,     isDuration: true),
    SleepInputField(label: 'REM Sleep',        controller: _remController,      isDuration: true),
    SleepInputField(label: 'Awake Time',       controller: _awakeController,    isDuration: true),
    SleepInputField(label: 'Time Gotten in Bed', controller: _inBedController, isDuration: false),
    SleepInputField(label: 'Time Asleep',      controller: _asleepController,   isDuration: false),
    SleepInputField(label: 'Time Awake',       controller: _wakeController,     isDuration: false),
  ];

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // ─── Date picker ───
      GestureDetector(
        onTap: () async {
          final initial = DateFormat.yMd().parse(_dateController.text);
          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            _dateController.text = DateFormat.yMd().format(picked);
            setState(() {});  // redraw label
          }
        },
        child: AbsorbPointer(
          child: TextField(
            controller: _dateController,
            decoration: const InputDecoration(labelText: 'Date'),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // ─── durations & times ───
      ...List.generate(inputs.length, (i) {
        final f = inputs[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _navigateToInput(inputs, i),
            child: AbsorbPointer(
              child: TextField(
                controller: f.controller,
                decoration: InputDecoration(labelText: f.label),
              ),
            ),
          ),
        );
      }),

      // ─── quality & notes ───
      TextField(
        controller: _qualityController,
        decoration: const InputDecoration(labelText: 'Quality'),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _notesController,
        decoration: const InputDecoration(labelText: 'Notes'),
        maxLines: 3,
      ),
    ],
  );
}


Future<void> _editSleepLog(
  String docId,
  String currentTotal,
  String currentDeep,
  String currentRem,
  String currentAwake,
  String currentAsleep,
  String currentAwakeTime,
  String currentQuality,
  String? currentNotes,
  String currentInBed,
  DateTime currentDate,
) async {
  final TextEditingController editTotalController = TextEditingController(text: currentTotal);
  final TextEditingController editDeepController = TextEditingController(text: currentDeep);
  final TextEditingController editRemController = TextEditingController(text: currentRem);
  final TextEditingController editAwakeController = TextEditingController(text: currentAwake);
  final TextEditingController editQualityController = TextEditingController(text: currentQuality);
  final TextEditingController editNotesController = TextEditingController(text: currentNotes ?? "");

  final DateTime? parsedInBed = DateTime.tryParse(currentInBed);
  final formattedInBed = parsedInBed != null
      ? DateFormat.jm().format(parsedInBed)
      : currentInBed;
  final TextEditingController editInBedController = TextEditingController(text: formattedInBed);

  final TextEditingController editAsleepController = TextEditingController(text: currentAsleep);
  final TextEditingController editAwakeTimeController = TextEditingController(text: currentAwakeTime);

  final inputs = [
    SleepInputField(label: 'Total Duration', controller: editTotalController, isDuration: true),
    SleepInputField(label: 'Deep Sleep', controller: editDeepController, isDuration: true),
    SleepInputField(label: 'REM Sleep', controller: editRemController, isDuration: true),
    SleepInputField(label: 'Awake Time', controller: editAwakeController, isDuration: true),
    SleepInputField(label: 'Time Gotten in Bed', controller: editInBedController, isDuration: false),
    SleepInputField(label: 'Time Asleep', controller: editAsleepController, isDuration: false),
    SleepInputField(label: 'Time Awake', controller: editAwakeTimeController, isDuration: false),
  ];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Sleep Log'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(inputs.length, (index) {
              final input = inputs[index];
              return GestureDetector(
                onTap: () async {
                  if (input.isDuration) {
                    await _showUnifiedPicker(inputs: inputs, currentIndex: index);
                  } else {
                    await _showUnifiedTimePicker(inputs: inputs, currentIndex: index);
                  }
                  setState(() {});
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: input.controller,
                    decoration: InputDecoration(labelText: input.label),
                  ),
                ),
              );
            }),
            TextField(
              controller: editQualityController,
              decoration: const InputDecoration(labelText: 'Quality'),
            ),
            TextField(
              controller: editNotesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            try {
            await _firestoreService.updateSleepLogAuto(
              docId:        docId,
              totalDuration: editTotalController.text.trim(),
              deepSleep:     editDeepController.text.trim(),
              remSleep:      editRemController.text.trim(),
              awakeTime:     editAwakeController.text.trim(),
              timeInBed:     editInBedController.text.trim(),
              timeAsleep:    editAsleepController.text.trim(),
              timeAwake:     editAwakeTimeController.text.trim(),
              quality:       editQualityController.text.trim(),
              notes:         editNotesController.text.trim(),
              date:          currentDate, 
            );

              Navigator.of(context).pop();
              _loadSleepLogs();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating log: $e')),
              );
            }
          },
          child: const Text('Save'),
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
    appBar: AppBar(title: const Text('Sleep Log')),
    floatingActionButton: FloatingActionButton(
      onPressed: _showAddSleepDialog,
      child: const Icon(Icons.add),
    ),
        body: Column(
      children: [
        // ── Charts + Toggle (fills top half) ──
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // 1) Real-time stream → chart
Expanded(
  child: StreamBuilder<List<Map<String, dynamic>>>(
    stream: _firestoreService.watchLogsForChart(_selectedWindow),
    builder: (context, snapshot) {
      // 1) always log what’s coming back:
      print('▶️ chart snapshot.hasData=${snapshot.hasData} '
            'length=${snapshot.data?.length} '
            'err=${snapshot.error} '
            'window=$_selectedWindow');

      // 2) if there's an error from Firestore at any point, show that:
      if (snapshot.hasError) {
        return Center(child: Text('Error loading chart: ${snapshot.error}'));
      }

      // 3) if we still haven’t gotten our first data event, show a spinner
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      // 4) now we know data != null
      final data = snapshot.data!;

      // 5) if it’s an empty list, show “no data”
      if (data.isEmpty) {
        return const Center(child: Text('No sleep data yet.'));
      }

      // 6) otherwise hand it off to your pager
      return SleepChartPager(
        sleepData: data,
        selectedWindow: _selectedWindow,
        onWindowChanged: (newWindow) {
          setState(() => _selectedWindow = newWindow);
        },
      );
    },
  ),
),
            ],
          ),
        ),

        // ── Logs list (fills bottom half) ──
        Expanded(
          flex: 2,
          child: FutureBuilder<List<QueryDocumentSnapshot>>(
            future: _sleepLogsFuture,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final logs = snap.data ?? [];
              if (logs.isEmpty) {
                return const Center(child: Text('No sleep logs saved yet.'));
              }
return ListView.builder(
  padding: const EdgeInsets.all(16),
  itemCount: logs.length,
  itemBuilder: (ctx, i) {
    // 1️⃣ grab the snapshot…
    final doc = logs[i];
    // 2️⃣ …and then its data map
    final d = doc.data() as Map<String, dynamic>;
    final ts = d['timestamp'] as Timestamp?;
    final date = ts == null
        ? 'No Date'
        : DateFormat.yMMMd().format(ts.toDate());

    return SleepEntryCard(
      date:         date,
      duration:     d['totalDuration'] ?? 'Unknown',
      quality:      d['quality']       ?? 'Unknown',
      sleepScore:   (d['sleepScore']   as num?)?.toString(),
      onEdit: () {
        final ts = (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        _editSleepLog(
          doc.id,
          d['totalDuration']  ?? '',
          d['deepSleep']      ?? '',
          d['remSleep']       ?? '',
          d['awakeTime']      ?? '',
          d['timeAsleep']     ?? '',
          d['timeAwake']      ?? '',
          d['quality']        ?? '',
          d['notes']          ?? '',
          d['timeInBed']      ?? '',
          ts,                         // ← pass the DateTime here
        );
      },
      onDelete:     () => _deleteSleepLog(doc.id),
    );
  },
);

            },
          ),
        ),
      ],
    ),

  );
}
}