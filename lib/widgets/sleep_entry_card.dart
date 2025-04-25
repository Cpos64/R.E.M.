import 'package:flutter/material.dart';

class SleepEntryCard extends StatelessWidget {
  final String duration;
  final String quality;
  final String? notes;
  final String date;
  final String? timeToFallAsleep;
  final String? timeInBed;
  final String? deepSleep;
  final String? remSleep;
  final String? lightSleep;
  final String? awakeTime;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SleepEntryCard({
    required this.duration,
    required this.quality,
    required this.date,
    this.notes,
    this.timeToFallAsleep,
    this.timeInBed,
    this.deepSleep,
    this.remSleep,
    this.lightSleep,
    this.awakeTime,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$date • $duration',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Quality: $quality',
                style: Theme.of(context).textTheme.bodyMedium),
            if (timeToFallAsleep != null)
              Text('Time to fall asleep: $timeToFallAsleep',
                  style: Theme.of(context).textTheme.bodySmall),
            if (timeInBed != null)
              Text('Time in bed: $timeInBed',
                  style: Theme.of(context).textTheme.bodySmall),
            if (deepSleep != null)
              Text('Deep: $deepSleep',
                  style: Theme.of(context).textTheme.bodySmall),
            if (remSleep != null)
              Text('REM: $remSleep',
                  style: Theme.of(context).textTheme.bodySmall),
            if (lightSleep != null)
              Text('Light: $lightSleep',
                  style: Theme.of(context).textTheme.bodySmall),
            if (awakeTime != null)
              Text('Awake: $awakeTime',
                  style: Theme.of(context).textTheme.bodySmall),
            if (notes != null && notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Notes: ${notes!}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
