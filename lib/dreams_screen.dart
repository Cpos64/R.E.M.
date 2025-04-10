import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:rem/widgets/dream_entry_card.dart';


class DreamsScreen extends StatefulWidget {
  const DreamsScreen({super.key});

  @override
  _DreamsScreenState createState() => _DreamsScreenState();
}

class _DreamsScreenState extends State<DreamsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editDescriptionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();


void _showAddDreamDialog() {
  _titleController.clear();
  _descriptionController.clear();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Title'),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: 'Description'),
            maxLines: 5,
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              await _saveDream();
              Navigator.of(context).pop();
              _scrollToBottom();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dream saved!')),
              );
            },
            child: Text('Save Dream'),
          ),
        ],
      ),
    ),
  );
}


  late Future<List<QueryDocumentSnapshot>> _dreamsFuture;
  String _editingDocId = '';
  bool _isEditing = false;
  String _filterKeyword = '';
  bool _isFirstLoad = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      _loadDreams();
      _isFirstLoad = false;
    }
  }

  void _scrollToBottom() {
  Future.delayed(Duration(milliseconds: 200), () {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}


  void _loadDreams() {
    setState(() {
      _dreamsFuture = _firestoreService.getDreams();
    });
  }

  Future<void> _saveDream() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isNotEmpty && description.isNotEmpty) {
      if (_isEditing) {
        await _firestoreService.updateDream(_editingDocId, title, description);
        _isEditing = false;
        _editingDocId = '';
      } else {
        await _firestoreService.saveDream(title, description);
      }

      _titleController.clear();
      _descriptionController.clear();
      _loadDreams();
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
              maxLines: 5,
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
              _loadDreams();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDream(String docId) async {
    await _firestoreService.deleteDream(docId);
    _loadDreams();
  }

  List<QueryDocumentSnapshot> _filterDreams(List<QueryDocumentSnapshot> dreams) {
    if (_filterKeyword.isEmpty) return dreams;

    return dreams.where((doc) {
      final title = doc['title'].toString().toLowerCase();
      final description = doc['description'].toString().toLowerCase();
      final keyword = _filterKeyword.toLowerCase();

      return title.contains(keyword) || description.contains(keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
  onPressed: _showAddDreamDialog,
  child: Icon(Icons.add),
),
      appBar: AppBar(title: Text('Dream Journal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Dreams',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _filterKeyword = value;
                });
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: _dreamsFuture,
                builder: (context, snapshot) {
                  print('Dreams snapshot: ${snapshot.connectionState}');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No dreams saved yet.'));
                  }

                  final dreams = _filterDreams(snapshot.data!);
                  print('Loaded ${dreams.length} dreams');

                  return ListView.builder(
                    itemCount: dreams.length,
                    controller: _scrollController,
                    itemBuilder: (context, index) {
                      final dream = dreams[index];
                      final docId = dream.id;
                      final title = dream['title'];
                      final description = dream['description'];
                      final timestamp = (dream.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      final formattedDate = timestamp != null
                          ? DateFormat.yMMMd().format(timestamp.toDate())
                          : 'No Date';

                                            return DreamEntryCard(
                        title: '$title • $formattedDate',
                        description: description,
                        onEdit: () => _editDream(docId, title, description),
                        onDelete: () => _deleteDream(docId),
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
