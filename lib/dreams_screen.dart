import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class DreamsScreen extends StatefulWidget {
  @override
  _DreamsScreenState createState() => _DreamsScreenState();
}

class _DreamsScreenState extends State<DreamsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editDescriptionController = TextEditingController();

  late Future<List<QueryDocumentSnapshot>> _dreamsFuture;

  @override
  void initState() {
    super.initState();
    _dreamsFuture = _loadDreams();
  }

  Future<List<QueryDocumentSnapshot>> _loadDreams() async {
    return await _firestoreService.getDreams();
  }

  Future<void> _saveDream() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isNotEmpty && description.isNotEmpty) {
      await _firestoreService.saveDream(title, description);
      _titleController.clear();
      _descriptionController.clear();

      setState(() {
        _dreamsFuture = _loadDreams();
      });
    }
  }

  Future<void> _editDream(String docId, String currentTitle, String currentDescription) async {
    _editTitleController.text = currentTitle;
    _editDescriptionController.text = currentDescription;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Dream'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _editTitleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _editDescriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = _editTitleController.text.trim();
              final newDescription = _editDescriptionController.text.trim();

              await _firestoreService.updateDream(docId, newTitle, newDescription);
              Navigator.of(context).pop();
              setState(() {
                _dreamsFuture = _loadDreams();
              });
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDream(String docId) async {
    await _firestoreService.deleteDream(docId);
    setState(() {
      _dreamsFuture = _loadDreams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dream Journal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Dream Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Dream Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveDream,
              child: Text('Save Dream'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: _dreamsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No dreams saved yet.'));
                  }

                  final dreams = snapshot.data!;

                  return ListView.builder(
                    itemCount: dreams.length,
                    itemBuilder: (context, index) {
                      final dream = dreams[index];
                      final docId = dream.id;
                      final title = dream['title'];
                      final description = dream['description'];

                      return Card(
                        child: ListTile(
                          title: Text(title),
                          subtitle: Text(description),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _editDream(docId, title, description),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteDream(docId),
                              ),
                            ],
                          ),
                        ),
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

