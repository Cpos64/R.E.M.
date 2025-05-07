import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sleep_log_service.dart';

class ViewSleepLogScreen extends StatefulWidget {
  final String docId;
  final String duration;
  final String quality;
  final DateTime timestamp;

  const ViewSleepLogScreen({
    super.key,
    required this.docId,
    required this.duration,
    required this.quality,
    required this.timestamp,
  });

  @override
  _ViewSleepLogScreenState createState() => _ViewSleepLogScreenState();
}

class _ViewSleepLogScreenState extends State<ViewSleepLogScreen> {
  final _sleepLogService = SleepLogService();
  final _durationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  late String _quality;

  @override
  void initState() {
    super.initState();
    _durationController.text = widget.duration;
    _quality = widget.quality;
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _saveSleepLog() async {
    if (!_formKey.currentState!.validate()) return;
    await _sleepLogService.updateSleepLog(
      widget.docId,
      _durationController.text,
      _quality,
      widget.timestamp, // keep original date
    );
    setState(() => _isEditing = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Log Details'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Date: ${DateFormat.yMMMd().format(widget.timestamp)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),

              // Duration
              TextFormField(
                controller: _durationController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Duration (e.g., 7h30m)',
                  enabled: _isEditing,
                ),
                enabled: _isEditing,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter duration';
                  if (!RegExp(r'^\d+h\d+m$').hasMatch(v)) {
                    return 'Format must be “XhYm”';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quality
              if (_isEditing)
                DropdownButtonFormField<String>(
                  value: _quality,
                  decoration: inputDecoration.copyWith(labelText: 'Sleep Quality'),
                  items: ['Good', 'Average', 'Poor']
                      .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                      .toList(),
                  onChanged: (v) => setState(() => _quality = v!),
                )
              else
                Text(
                  'Quality: $_quality',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isEditing
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveSleepLog,
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
