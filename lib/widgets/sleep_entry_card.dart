import 'package:flutter/material.dart';

class SleepEntryCard extends StatelessWidget {
  final String date;
  final String duration;
  final String quality;
  final String? sleepScore;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SleepEntryCard({
    required this.date,
    required this.duration,
    required this.quality,
    this.sleepScore,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          '$date • $duration',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Text(
          'Quality: $quality'
          '${sleepScore != null ? ' • Score: $sleepScore' : ''}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
