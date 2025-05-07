// lib/screens/dreams_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firestore_service.dart';
import '../widgets/dream_entry_card.dart';

/// A reusable form widget for adding/editing dreams.
class DreamForm extends StatelessWidget {
  final TextEditingController titleCtl;
  final TextEditingController descCtl;
  final VoidCallback onSubmit;

  const DreamForm({
    required this.titleCtl,
    required this.descCtl,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleCtl,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descCtl,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onSubmit,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class DreamsScreen extends StatefulWidget {
  const DreamsScreen({super.key});

  @override
  State<DreamsScreen> createState() => _DreamsScreenState();
}

class _DreamsScreenState extends State<DreamsScreen> {
  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _scrollController = ScrollController();
  String _filterKeyword = '';

  Stream<QuerySnapshot> get _dreamsStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('dreams')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _applyFilter(List<QueryDocumentSnapshot> docs) {
    if (_filterKeyword.isEmpty) return docs;
    final kw = _filterKeyword.toLowerCase();
    return docs.where((d) {
      final t = (d['title'] as String).toLowerCase();
      final b = (d['description'] as String).toLowerCase();
      return t.contains(kw) || b.contains(kw);
    }).toList();
  }

  void _showAddDream() {
    _titleController.clear();
    _descController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DreamForm(
        titleCtl: _titleController,
        descCtl: _descController,
        onSubmit: () async {
          final t = _titleController.text.trim();
          final d = _descController.text.trim();
          if (t.isNotEmpty && d.isNotEmpty) {
            await FirestoreService().saveDream(t, d);
            Navigator.of(context).pop();
            // scroll to bottom
            Future.delayed(const Duration(milliseconds: 200), () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dream saved!')),
            );
          }
        },
      ),
    );
  }

  void _editDream(QueryDocumentSnapshot doc) {
    _titleController.text = doc['title'];
    _descController.text = doc['description'];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Dream'),
        content: DreamForm(
          titleCtl: _titleController,
          descCtl: _descController,
          onSubmit: () async {
            final t = _titleController.text.trim();
            final d = _descController.text.trim();
            if (t.isNotEmpty && d.isNotEmpty) {
              await FirestoreService().updateDream(doc.id, t, d);
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteDream(String id) async {
    await FirestoreService().deleteDream(id);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Dream deleted')));
  }

  Widget _buildSearchBar() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search dreams',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
          suffixIcon: _filterKeyword.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _filterKeyword = '');
                  },
                ),
        ),
        onChanged: (v) => setState(() => _filterKeyword = v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dream Journal')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDream,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _dreamsStream,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No dreams yet.'));
                  }
                  final filtered = _applyFilter(docs);
                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final doc = filtered[i];
                      final ts = (doc['timestamp'] as Timestamp).toDate();
                      final date = DateFormat.yMMMd().format(ts);
                      return Dismissible(
                        key: Key(doc.id),
                        background: Container(color: Colors.red),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteDream(doc.id),
                        child: DreamEntryCard(
                          title: '${doc['title']} • $date',
                          description: doc['description'],
                          onEdit: () => _editDream(doc),
                          onDelete: () => _deleteDream(doc.id),
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
