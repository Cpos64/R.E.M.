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

  late Future<List<QueryDocumentSnapshot>> _dreamsFuture;

  @override
  void initState() {
    super.initState();
    _dreamsFuture = _loadDreams();
  }

  Future<List<QueryDocumentSnapshot>> _loadDreams() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('dreams')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs;
  }

  Future<void> _saveDream() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isNotEmpty && description.isNotEmpty) {
      await _firestoreService.saveDream(title, description);
      _titleController.clear();
      _descriptionController.clear();

      // Refresh dreams list
      setState(() {
        _dreamsFuture = _loadDreams();
      });
    }
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
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text('Save Dream'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: _dreamsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading dreams.'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No dreams saved yet.'));
                  }

                  final dreams = snapshot.data!;

                  return ListView.builder(
                    itemCount: dreams.length,
                    itemBuilder: (context, index) {
                      final dream = dreams[index];
                      final timestamp = dream['timestamp'] as Timestamp?;
                      final date = timestamp != null ? timestamp.toDate() : DateTime.now();

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(dream['title']),
                          subtitle: Text(
                            'Date: ${date.toLocal().toString().split(' ')[0]}\nDescription: ${dream['description']}',
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
