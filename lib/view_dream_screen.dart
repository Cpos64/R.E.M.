import 'package:flutter/material.dart';
import 'firestore_service.dart';

class ViewDreamScreen extends StatefulWidget {
  final String docId;
  final String title;
  final String description;
  final DateTime timestamp;

  const ViewDreamScreen({super.key, 
    required this.docId,
    required this.title,
    required this.description,
    required this.timestamp,
  });

  @override
  _ViewDreamScreenState createState() => _ViewDreamScreenState();
}

class _ViewDreamScreenState extends State<ViewDreamScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isEditing = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.title;
    _descriptionController.text = widget.description;
  }

  Future<void> _saveDream() async {
    await _firestoreService.updateDream(widget.docId, _titleController.text, _descriptionController.text);
    setState(() {
      _isEditing = false;
    });
    Navigator.of(context).pop(true); // Return to previous screen after editing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Dream'),
        actions: _isEditing
            ? [
                IconButton(
                  icon: Icon(Icons.save),
                  onPressed: _saveDream,
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
              ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${widget.timestamp.toLocal().toString().split(' ')[0]}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
              enabled: _isEditing,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 5,
              enabled: _isEditing,
            ),
          ],
        ),
      ),
    );
  }
}
