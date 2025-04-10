import 'package:flutter/material.dart';

class SleepEntryCard extends StatelessWidget {
  final String duration;
  final String quality;
  final String? notes;
  final String date;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SleepEntryCard({
    required this.duration,
    required this.quality,
    required this.date,
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
            Text('$date • $duration',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Quality: $quality',
                style: Theme.of(context).textTheme.bodyMedium),
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
