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

  // controllers for Add dialog
  final _durationController = TextEditingController();
  final _deepController     = TextEditingController();
  final _remController      = TextEditingController();
  final _awakeController    = TextEditingController();
  final _asleepController   = TextEditingController();
  final _wakeController     = TextEditingController();
  final _qualityController  = TextEditingController();
  final _notesController    = TextEditingController();
  final _dateController     = TextEditingController(text: DateFormat.yMd().format(DateTime.now()));
  final _inBedController    = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      _loadSleepLogs();
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['add'] == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showAddSleepDialog());
      }
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
    if (input.isDuration) {
      _showUnifiedPicker(inputs: inputs, currentIndex: index);
    } else {
      _showUnifiedTimePicker(inputs: inputs, currentIndex: index);
    }
  }

  Future<void> _showUnifiedPicker({
    required List<SleepInputField> inputs,
    required int currentIndex,
  }) async {
    final controller = inputs[currentIndex].controller;
    final initialValue = controller.text;
    final minutes = _parseToMinutes(initialValue);
    Duration selected = Duration(minutes: minutes);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).dialogBackgroundColor,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(inputs[currentIndex].label,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: selected,
                      onTimerDurationChanged: (d) => selected = d,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: currentIndex > 0
                            ? () {
                                Navigator.pop(context);
                                _showUnifiedPicker(
                                  inputs: inputs,
                                  currentIndex: currentIndex - 1,
                                );
                              }
                            : null,
                        child: Text('Back'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final h = selected.inHours;
                          final m = selected.inMinutes % 60;
                          controller.text = '${h}h${m}m';
                          Navigator.pop(context);
                        },
                        child: Text('Done'),
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
                        child: Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showUnifiedTimePicker({
    required List<SleepInputField> inputs,
    required int currentIndex,
  }) async {
    final controller = inputs[currentIndex].controller;
    TimeOfDay initial = TimeOfDay.now();
    try {
      final m = RegExp(r':(\d+)').firstMatch(controller.text)?.group(1) ?? '0';
      final h = RegExp(r'(\d+):').firstMatch(controller.text)?.group(1) ?? '0';
      initial = TimeOfDay(hour: int.parse(h), minute: int.parse(m));
    } catch (_) {}

    DateTime now = DateTime.now();
    DateTime selected = DateTime(now.year, now.month, now.day, initial.hour, initial.minute);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).dialogBackgroundColor,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(inputs[currentIndex].label,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: selected,
                      use24hFormat: false,
                      onDateTimeChanged: (d) => selected = d,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: currentIndex > 0
                            ? () {
                                Navigator.pop(context);
                                _showUnifiedTimePicker(
                                  inputs: inputs,
                                  currentIndex: currentIndex - 1,
                                );
                              }
                            : null,
                        child: Text('Back'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          controller.text = DateFormat.jm().format(selected);
                          Navigator.pop(context);
                        },
                        child: Text('Done'),
                      ),
                      TextButton(
                        onPressed: currentIndex < inputs.length - 1
                            ? () {
                                controller.text = DateFormat.jm().format(selected);
                                Navigator.pop(context);
                                _navigateToInput(inputs, currentIndex + 1);
                              }
                            : null,
                        child: Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSleepDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Sleep Log'),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: _buildSleepFormContent(),
          ),
        ),
        actions: [
          TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: Text('Save Sleep Log'),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              try {
                final parsedDate = DateFormat.yMd().parse(_dateController.text.trim());
                final now = DateTime.now();
                final fullDate = DateTime(
                  parsedDate.year,
                  parsedDate.month,
                  parsedDate.day,
                  now.hour,
                  now.minute,
                  now.second,
                );
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
                  date:          fullDate,
                );
                // clear
                _dateController.text = DateFormat.yMd().format(DateTime.now());
                _durationController.clear();
                _deepController.clear();
                _remController.clear();
                _awakeController.clear();
                _inBedController.clear();
                _asleepController.clear();
                _wakeController.clear();
                _qualityController.clear();
                _notesController.clear();
                Navigator.pop(context);
                _loadSleepLogs();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error saving sleep log: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSleepFormContent() {
    // Date picker at the top
    final inputs = <SleepInputField>[
      SleepInputField(label: 'Total Duration', controller: _durationController, isDuration: true),
      SleepInputField(label: 'Deep Sleep',     controller: _deepController,     isDuration: true),
      SleepInputField(label: 'REM Sleep',      controller: _remController,      isDuration: true),
      SleepInputField(label: 'Awake Time',     controller: _awakeController,    isDuration: true),
      SleepInputField(label: 'Time Gotten in Bed', controller: _inBedController, isDuration: false),
      SleepInputField(label: 'Time Asleep',    controller: _asleepController,   isDuration: false),
      SleepInputField(label: 'Time Awake',     controller: _wakeController,     isDuration: false),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Date field
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateFormat.yMd().parse(_dateController.text),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _dateController.text = DateFormat.yMd().format(picked);
              });
            }
          },
          child: AbsorbPointer(
            child: TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Date'),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Duration/time pickers
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

        const SizedBox(height: 16),
        // Quality & Notes
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
    String   docId,
    String   currentTotal,
    String   currentDeep,
    String   currentRem,
    String   currentAwake,
    String   currentTimeInBed,
    String   currentTimeAsleep,
    String   currentTimeAwake,
    String   currentQuality,
    String?  currentNotes,
    DateTime currentDate,
  ) async {
    final editTotalController     = TextEditingController(text: currentTotal);
    final editDeepController      = TextEditingController(text: currentDeep);
    final editRemController       = TextEditingController(text: currentRem);
    final editAwakeController     = TextEditingController(text: currentAwake);
    final editInBedController     = TextEditingController(text: currentTimeInBed);
    final editAsleepController    = TextEditingController(text: currentTimeAsleep);
    final editAwakeTimeController = TextEditingController(text: currentTimeAwake);
    final editQualityController   = TextEditingController(text: currentQuality);
    final editNotesController     = TextEditingController(text: currentNotes ?? "");
    final editDateController      = TextEditingController(text: DateFormat.yMd().format(currentDate));

    final editInputs = <SleepInputField>[
      SleepInputField(label: 'Total Duration', controller: editTotalController,   isDuration: true),
      SleepInputField(label: 'Deep Sleep',     controller: editDeepController,    isDuration: true),
      SleepInputField(label: 'REM Sleep',      controller: editRemController,     isDuration: true),
      SleepInputField(label: 'Awake Time',     controller: editAwakeController,   isDuration: true),
      SleepInputField(label: 'Time in Bed',    controller: editInBedController,   isDuration: false),
      SleepInputField(label: 'Time Asleep',    controller: editAsleepController,  isDuration: false),
      SleepInputField(label: 'Time Awake',     controller: editAwakeTimeController,isDuration: false),
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Sleep Log'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // date picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateFormat.yMd().parse(editDateController.text),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  editDateController.text = DateFormat.yMd().format(picked);
                  setState(() {}); 
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: editDateController,
                  decoration: InputDecoration(labelText: 'Date'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // sleep fields
            ...List.generate(editInputs.length, (i) {
              final f = editInputs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _navigateToInput(editInputs, i),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: f.controller,
                      decoration: InputDecoration(labelText: f.label),
                    ),
                  ),
                ),
              );
            }),
            // quality & notes
            TextField(
              controller: editQualityController,
              decoration: InputDecoration(labelText: 'Quality'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: editNotesController,
              decoration: InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
          ]),
        ),
        actions: [
          TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: Text('Save'),
            onPressed: () async {
              final newDate = DateFormat.yMd().parse(editDateController.text);
              final fullDate = DateTime(
                newDate.year,
                newDate.month,
                newDate.day,
                currentDate.hour,
                currentDate.minute,
                currentDate.second,
              );
              await _firestoreService.updateSleepLogAuto(
                docId:         docId,
                totalDuration: editTotalController.text.trim(),
                deepSleep:     editDeepController.text.trim(),
                remSleep:      editRemController.text.trim(),
                awakeTime:     editAwakeController.text.trim(),
                timeInBed:     editInBedController.text.trim(),
                timeAsleep:    editAsleepController.text.trim(),
                timeAwake:     editAwakeTimeController.text.trim(),
                quality:       editQualityController.text.trim(),
                notes:         editNotesController.text.trim(),
                date:          fullDate,
              );
              Navigator.pop(context);
              _loadSleepLogs();
            },
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
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.watchLogsForChart(_selectedWindow),
              builder: (ctx, snap) {
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                if (!snap.hasData) return Center(child: CircularProgressIndicator());
                final data = snap.data!;
                // Always show the chart pager so the user can switch windows
                // even when the current range has no entries.
                return SleepChartPager(
                  sleepData: data,
                  selectedWindow: _selectedWindow,
                  onWindowChanged: (w) => setState(() => _selectedWindow = w),
                );
              },
            ),
          ),

          // ── Logs list (fills bottom half) ──
          Expanded(
            flex: 2,
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: _sleepLogsFuture,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                final logs = snap.data ?? [];
                if (logs.isEmpty) return Center(child: Text('No sleep logs saved yet.'));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (ctx, i) {
                    final doc = logs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final ts = (d['timestamp'] as Timestamp?)?.toDate();
                    final date = ts == null ? 'No Date' : DateFormat.yMMMd().format(ts);
                    return SleepEntryCard(
                      date:       date,
                      duration:   d['totalDuration'] ?? '—',
                      quality:    d['quality']       ?? '—',
                      sleepScore: (d['sleepScore']   as num?)?.toString(),
                      onEdit: () {
                        final ts = (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                        _editSleepLog(
                          doc.id,
                          d['totalDuration'] ?? '',
                          d['deepSleep']     ?? '',
                          d['remSleep']      ?? '',
                          d['awakeTime']     ?? '',
                          d['timeInBed']     ?? '',
                          d['timeAsleep']    ?? '',
                          d['timeAwake']     ?? '',
                          d['quality']       ?? '',
                          d['notes']         ?? '',
                          ts,
                        );
                      },
                      onDelete: () => _deleteSleepLog(doc.id),
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