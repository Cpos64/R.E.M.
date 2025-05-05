import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String _formatTimeString(String raw) {
  final dt = DateTime.tryParse(raw);
  if (dt != null) {
    return DateFormat.jm().format(dt);
  }
  return raw; // fallback if it isn’t a parseable ISO string
}

class SleepEntryCard extends StatelessWidget {
  final String date;
  final String duration;
  final String quality;
  final String? sleepScore;
  final String? timeInBed;
  final String? deepSleep;
  final String? remSleep;
  final String? lightSleep;
  final String? awakeTime;
  final String? notes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SleepEntryCard({
    required this.date,
    required this.duration,
    required this.quality,
    this.sleepScore,
    this.timeInBed,
    this.deepSleep,
    this.remSleep,
    this.lightSleep,
    this.awakeTime,
    this.notes,
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
            // Header: date and total duration
            Text(
              '$date • $duration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Quality and (optional) sleep score side-by-side
            Row(
              children: [
                Text(
                  'Quality: $quality',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (sleepScore != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    'Score: $sleepScore',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Detailed breakdown of stages
if (timeInBed != null)
  Text(
    'Time in bed: ${_formatTimeString(timeInBed!)}',
    style: Theme.of(context).textTheme.bodySmall,
  ),

            if (deepSleep != null)
              Text(
                'Deep: $deepSleep',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (remSleep != null)
              Text(
                'REM: $remSleep',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (lightSleep != null)
              Text(
                'Light: $lightSleep',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (awakeTime != null)
              Text(
                'Awake: $awakeTime',
                style: Theme.of(context).textTheme.bodySmall,
              ),

            // Notes, if present
            if (notes != null && notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                notes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 12),
            // Edit/Delete buttons
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
            ),
          ],
        ),
      ),
    );
  }
}
