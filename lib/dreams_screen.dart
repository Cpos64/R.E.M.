import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firestore_service.dart';
import '../widgets/dream_entry_card.dart';

/// A reusable form widget for adding/editing dreams with Genre selection.
class DreamForm extends StatefulWidget {
  final TextEditingController titleCtl;
  final TextEditingController descCtl;
  final String? initialGenre;
  final List<String> genres;
  final void Function(String genre) onSubmit;

  const DreamForm({
    Key? key,
    required this.titleCtl,
    required this.descCtl,
    this.initialGenre,
    required this.genres,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _DreamFormState createState() => _DreamFormState();
}

class _DreamFormState extends State<DreamForm> {
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _selectedGenre = widget.initialGenre;
  }

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
            controller: widget.titleCtl,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.descCtl,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          // Genre dropdown
          DropdownButtonFormField<String>(
            value: _selectedGenre,
            items: widget.genres.map((g) => DropdownMenuItem(
              value: g,
              child: Text(g),
            )).toList(),
            onChanged: (val) => setState(() => _selectedGenre = val),
            decoration: const InputDecoration(
              labelText: 'Genre',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _selectedGenre == null
                    ? null
                    : () => widget.onSubmit(_selectedGenre!),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DreamsScreen extends StatefulWidget {
  const DreamsScreen({Key? key}) : super(key: key);

  @override
  State<DreamsScreen> createState() => _DreamsScreenState();
}

class _DreamsScreenState extends State<DreamsScreen> {
  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _scrollController = ScrollController();
  String _filterKeyword = '';

  static const _genreOptions = [
    'Nightmare','Lucid','Adventure','Recurring','Emotional',
    'Weird','Romantic','Meaningful','Problem-Solving', 'Tragedy', 'Other'
  ];

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
    // 1️⃣ pull out the raw data map
    final data  = d.data() as Map<String,dynamic>;

    // 2️⃣ guard against missing genre
    final genre = (data['genre'] as String?)?.toLowerCase() ?? '';

    // 3️⃣ now lookup title/description off the same map
    final t = (data['title']       as String).toLowerCase();
    final b = (data['description'] as String).toLowerCase();
      return t.contains(kw) || b.contains(kw) || genre.contains(kw);
    }).toList();
  }

  /// Animate the list up to the newest item at the bottom.
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

void _showAddDream() {
  _titleController.clear();
  _descController.clear();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // lets the sheet go full-screen
    builder: (context) {
      // 1) add bottom padding equal to the keyboard height
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        // 2) make the whole thing scrollable
        child: SingleChildScrollView(
          // 3) you can also constrain width if you like:
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: DreamForm(
              titleCtl: _titleController,
              descCtl:  _descController,
              genres:   _genreOptions,
              onSubmit: (genre) async {
                final t = _titleController.text.trim();
                final d = _descController.text.trim();
                if (t.isEmpty || d.isEmpty) return;
                await FirestoreService().saveDream(t, d, genre);
                Navigator.of(context).pop();
                _scrollToBottom();
              },
            ),
          ),
        ),
      );
    },
  );
}

  void _editDream(QueryDocumentSnapshot doc) {
    _titleController.text = doc['title'];
    _descController.text  = doc['description'];
    final existingGenre = doc['genre'] as String?;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Dream'),
        content: DreamForm(
          titleCtl:     _titleController,
          descCtl:      _descController,
          initialGenre: existingGenre,
          genres:       _genreOptions,
          onSubmit: (genre) async {
            final t = _titleController.text.trim();
            final d = _descController.text.trim();
            if (t.isEmpty || d.isEmpty) return;
            await FirestoreService().updateDream(doc.id, t, d, genre);
            Navigator.of(context).pop();
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

                      // 1) Defensive read of the raw map:
                      final data  = doc.data() as Map<String, dynamic>;

                      // 2) Extract your fields, giving genre a safe default:
                      final ts    = (data['timestamp'] as Timestamp).toDate();
                      final date  = DateFormat.yMMMd().format(ts);
                      final genre = (data['genre'] as String?)?.trim() ?? 'Other';

                      return Dismissible(
                        key: Key(doc.id),
                        background: Container(color: Colors.red),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteDream(doc.id),
                        child: DreamEntryCard(
                          title:       data['title'] as String,
                          date:        ts, 
                          description: data['description'] as String,
                          tags:        [genre],
                          onShare:     () {
                            // optional: share this dream
                            // e.g. Share.share('$date — ${data['title']}\n\n${data['description']}');
                          },
                          onEdit:      () => _editDream(doc),
                          onDelete:    () => _deleteDream(doc.id),
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
