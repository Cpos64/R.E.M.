// lib/screens/view_dream_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firestore_service.dart';

class ViewDreamScreen extends StatefulWidget {
  final String docId;
  final String title;
  final String description;
  final DateTime timestamp;
  final List<String> tags;
  final double sentimentScore;
  final int recallRating; // ← added here

  const ViewDreamScreen({
    Key? key,
    required this.docId,
    required this.title,
    required this.description,
    required this.timestamp,
    this.tags = const [],
    this.sentimentScore = 0.0,
    required this.recallRating, // ← added here
  }) : super(key: key);

  @override
  _ViewDreamScreenState createState() => _ViewDreamScreenState();
}

class _ViewDreamScreenState extends State<ViewDreamScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _descriptionController = TextEditingController(text: widget.description);
    _tags = List.from(widget.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

Future<void> _saveDream() async {
  final newTitle = _titleController.text.trim();
  final newDesc  = _descriptionController.text.trim();
  if (newTitle.isEmpty || newDesc.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Title and description cannot be empty')),
    );
    return;
  }

  // let's assume you pulled the original recallRating in initState:
  await _firestoreService.updateDream(
    id:            widget.docId,
    title:         newTitle,
    description:   newDesc,
    genres:        _tags,
    recallRating:  widget.recallRating, 
  );

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Dream updated')),
  );

  setState(() => _isEditing = false);
  Navigator.of(context).pop(true); // tell previous screen you changed it
}

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMMd().format(widget.timestamp);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Dream' : 'View Dream'),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Save changes',
                  onPressed: _saveDream,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit dream',
                  onPressed: () => setState(() => _isEditing = true),
                ),
              ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isEditing
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    // Tag editor
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in _tags)
                          Chip(
                            label: Text(tag),
                            onDeleted: () => setState(() => _tags.remove(tag)),
                          ),
                        ActionChip(
                          label: const Text('Add Tag'),
                          onPressed: () async {
                            final newTag = await _showTagInput();
                            if (newTag != null && newTag.isNotEmpty) {
                              setState(() => _tags.add(newTag));
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (widget.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: widget.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Sentiment: ${widget.sentimentScore.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
      ),
    );
  }

  Future<String?> _showTagInput() {
    final ctl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Tag'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(hintText: 'Enter tag'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(ctl.text.trim()), child: const Text('Add')),
        ],
      ),
    );
  }
}