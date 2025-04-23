import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'firestore_service.dart';
import 'widgets/sleep_score_chart.dart';
import 'widgets/sleep_stage_bar_chart.dart';
import 'widgets/sleep_chart_pager.dart';
import 'widgets/sleep_entry_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class SleepLogScreen extends StatefulWidget {
  const SleepLogScreen({super.key});

  @override
  _SleepLogScreenState createState() => _SleepLogScreenState();
}

class _SleepLogScreenState extends State<SleepLogScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<QueryDocumentSnapshot>> _sleepLogsFuture;
  List<Map<String, dynamic>> sleepChartData = [];
  bool _isFirstLoad = true;

  final _durationController = TextEditingController();
  final _deepController = TextEditingController();
  final _remController = TextEditingController();
  final _awakeController = TextEditingController();
  final _asleepController = TextEditingController();
  final _wakeController = TextEditingController();
  final _qualityController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      _loadSleepLogs();
      _loadChartData();
      _isFirstLoad = false;
    }
  }

  void _loadSleepLogs() {
    setState(() {
      _sleepLogsFuture = _firestoreService.getSleepLogs();
    });
  }

  void _loadChartData() async {
    final chartData = await _firestoreService.getLast7SleepLogsForChart();
    setState(() {
      sleepChartData = chartData;
    });
  }

Future<void> _showDurationPickerWithFlow({
  required List<TextEditingController> controllers,
  required int currentIndex,
}) async {
  final controller = controllers[currentIndex];
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
                                _showDurationPickerWithFlow(
                                  controllers: controllers,
                                  currentIndex: currentIndex - 1,
                                );
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
                        onPressed: currentIndex < controllers.length - 1
                            ? () {
                                final h = selected.inHours;
                                final m = selected.inMinutes % 60;
                                controller.text = '${h}h${m}m';
                                Navigator.pop(context);
                                _showDurationPickerWithFlow(
                                  controllers: controllers,
                                  currentIndex: currentIndex + 1,
                                );
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

Future<void> _showTimePickerWithFlow({
  required List<TextEditingController> controllers,
  required int currentIndex,
}) async {
  final controller = controllers[currentIndex];
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
                                _showTimePickerWithFlow(
                                  controllers: controllers,
                                  currentIndex: currentIndex - 1,
                                );
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
                        onPressed: currentIndex < controllers.length - 1
                            ? () {
                                final formatted = DateFormat.jm().format(selected);
                                controller.text = formatted;
                                Navigator.pop(context);
                                _showTimePickerWithFlow(
                                  controllers: controllers,
                                  currentIndex: currentIndex + 1,
                                );
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


int _parseToMinutes(String input) {
  final hours = RegExp(r'(\d+)h').firstMatch(input)?.group(1);
  final minutes = RegExp(r'(\d+)m').firstMatch(input)?.group(1);
  return (int.tryParse(hours ?? '0') ?? 0) * 60 + (int.tryParse(minutes ?? '0') ?? 0);
}

void _showAddSleepDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Sleep Log'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: _buildSleepFormContent(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            try {
              await _firestoreService.saveSleepLogAuto(
                totalDuration: _durationController.text.trim(),
                deepSleep: _deepController.text.trim(),
                remSleep: _remController.text.trim(),
                awakeTime: _awakeController.text.trim(),
                timeAsleep: _asleepController.text.trim(),
                timeAwake: _wakeController.text.trim(),
                quality: _qualityController.text.trim(),
                notes: _notesController.text.trim(),
              );

              _durationController.clear();
              _deepController.clear();
              _remController.clear();
              _awakeController.clear();
              _asleepController.clear();
              _wakeController.clear();
              _qualityController.clear();
              _notesController.clear();

              Navigator.of(context).pop();
              _loadSleepLogs();
              _loadChartData();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving sleep log')),
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
  final durationControllers = [
    _durationController,
    _deepController,
    _remController,
    _awakeController,
  ];

  final timeControllers = [
    _asleepController,
    _wakeController,
  ];

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ...List.generate(durationControllers.length, (index) {
        final label = [
          'Total Duration',
          'Deep Sleep',
          'REM Sleep',
          'Awake Time'
        ][index];

        return GestureDetector(
          onTap: () async {
            await _showDurationPickerWithFlow(
              controllers: durationControllers,
              currentIndex: index,
            );
            setState(() {});
          },
          child: AbsorbPointer(
            child: TextField(
              controller: durationControllers[index],
              decoration: InputDecoration(labelText: label),
            ),
          ),
        );
      }),

      ...List.generate(timeControllers.length, (index) {
        final label = ['Time Asleep', 'Time Awake'][index];
        final controller = timeControllers[index];

        return GestureDetector(
          onTap: () async {
            await _showTimePickerWithFlow(
              controllers: timeControllers,
              currentIndex: index,
            );
            setState(() {});
          },
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(labelText: label),
            ),
          ),
        );
      }),

      TextField(
        controller: _qualityController,
        decoration: const InputDecoration(labelText: 'Quality'),
      ),
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
  String currentLight,
  int currentScore,
  String currentAsleep,
  String currentAwakeTime,
  String currentQuality,
  String? currentNotes,
) async {
  final TextEditingController editTotalController = TextEditingController(text: currentTotal);
  final TextEditingController editDeepController = TextEditingController(text: currentDeep);
  final TextEditingController editRemController = TextEditingController(text: currentRem);
  final TextEditingController editAwakeController = TextEditingController(text: currentAwake);
  final TextEditingController editLightController = TextEditingController(text: currentLight);
  final TextEditingController editScoreController = TextEditingController(text: currentScore.toString());
  final TextEditingController editAsleepController = TextEditingController(text: currentAsleep);
  final TextEditingController editAwakeTimeController = TextEditingController(text: currentAwakeTime);
  final TextEditingController editQualityController = TextEditingController(text: currentQuality);
  final TextEditingController editNotesController = TextEditingController(text: currentNotes ?? "");

  final durationControllers = [
    editTotalController,
    editDeepController,
    editRemController,
    editAwakeController,
  ];

  final timeControllers = [
    editAsleepController,
    editAwakeTimeController,
  ];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Sleep Log'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(durationControllers.length, (index) {
              final label = ['Total Duration', 'Deep Sleep', 'REM Sleep', 'Awake Time'][index];
              final controller = durationControllers[index];

              return GestureDetector(
                onTap: () async {
                  await _showDurationPickerWithFlow(
                    controllers: durationControllers,
                    currentIndex: index,
                  );
                  setState(() {});
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(labelText: label),
                  ),
                ),
              );
            }),

            TextField(
              controller: editLightController,
              decoration: const InputDecoration(labelText: 'Light Sleep'),
            ),
            TextField(
              controller: editScoreController,
              decoration: const InputDecoration(labelText: 'Sleep Score (0–100)'),
              keyboardType: TextInputType.number,
            ),

            ...List.generate(timeControllers.length, (index) {
              final label = ['Time Asleep', 'Time Awake'][index];
              final controller = timeControllers[index];

              return GestureDetector(
                onTap: () async {
                  await _showTimePickerWithFlow(
                    controllers: timeControllers,
                    currentIndex: index,
                  );
                  setState(() {});
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(labelText: label),
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
              await _firestoreService.updateSleepLog(
                docId,
                editTotalController.text.trim(),
                editDeepController.text.trim(),
                editRemController.text.trim(),
                editLightController.text.trim(),
                editAwakeController.text.trim(),
                int.tryParse(editScoreController.text.trim()) ?? 0,
                editAsleepController.text.trim(),
                editAwakeTimeController.text.trim(),
                editQualityController.text.trim(),
                editNotesController.text.trim(),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sleepChartData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SleepChartPager(sleepData: sleepChartData),
              ),
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future: _sleepLogsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: \${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No sleep logs saved yet.'));
                }

                final logs = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: logs.map((log) {
                      final data = log.data() as Map<String, dynamic>;
                      final timestamp = data['timestamp'] as Timestamp?;
                      final formattedDate = timestamp != null ? DateFormat.yMMMd().format(timestamp.toDate()) : 'No Date';

                      return SleepEntryCard(
                        duration: data['totalDuration'] ?? 'Unknown',
                        quality: data['quality'] ?? 'Unknown',
                        date: formattedDate,
                        onEdit: () => _editSleepLog(
                          log.id,
                          data['totalDuration'] ?? '',
                          data['deepSleep'] ?? '',
                          data['remSleep'] ?? '',
                          data['awakeTime'] ?? '',
                          data['lightSleep'] ?? '',
                          (data['sleepScore'] as num?)?.toInt() ?? 0,
                          data['timeAsleep'] ?? '',
                          data['timeAwake'] ?? '',
                          data['quality'] ?? '',
                          data['notes'] ?? '',
                        ),
                        onDelete: () => _deleteSleepLog(log.id),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
    