import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firestore_service.dart';
import '../widgets/dream_entry_card.dart';
import '../widgets/dream_chart_pager.dart';
import '../widgets/dream_genre_pie_chart.dart';
import '../widgets/dream_sentiment_line_chart.dart';


/// A reusable form widget for adding/editing dreams with up to 2 genre tags.
class DreamForm extends StatefulWidget {
  final TextEditingController titleCtl;
  final TextEditingController descCtl;
  final List<String> genres;
  final List<String>? initialGenres;
  final int? initialRating;
  final void Function(List<String> genres, int recallRating, DateTime date) onSubmit;
  final DateTime? initialDate;

  const DreamForm({
    Key? key,
    required this.titleCtl,
    required this.descCtl,
    required this.genres,
    this.initialGenres,
    this.initialRating,
    this.initialDate,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _DreamFormState createState() => _DreamFormState();
}

class _DreamFormState extends State<DreamForm> {
  late List<String> _selectedGenres;
  late int _recallRating;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedGenres = List.from(widget.initialGenres ?? []);
    _recallRating = widget.initialRating ?? 5;
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  Widget _buildGenreChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: widget.genres.map((g) {
        final selected = _selectedGenres.contains(g);
        return ChoiceChip(
          label: Text(g),
          selected: selected,
          onSelected: (on) {
            setState(() {
              if (on) {
                if (_selectedGenres.length < 2) _selectedGenres.add(g);
              } else {
                _selectedGenres.remove(g);
              }
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
              // ── DATE PICKER ROW ──
        Row(
          children: [
            Text(
              'Date: ${DateFormat.yMMMd().format(_selectedDate)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            TextButton(
              child: const Text('Change'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
          // Title & Description
          TextField(controller: widget.titleCtl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(
            controller: widget.descCtl,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 4,
          ),

          const SizedBox(height: 12),

          // Genre chips (up to 2)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Genres (up to 2)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          _buildGenreChips(),

          const SizedBox(height: 12),

          // Recall slider
          Row(
            children: [
              Text('Recall: $_recallRating'),
              Expanded(
                child: Slider(
                  value: _recallRating.toDouble(),
                  min: 0, max: 10, divisions: 10,
                  label: '$_recallRating',
                  onChanged: (v) => setState(() => _recallRating = v.round()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: _selectedGenres.isEmpty
                    ? null
                    : () => widget.onSubmit(_selectedGenres, _recallRating, _selectedDate),
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
  final List<String> _selectedTags = [];

static const _genreOptions = [
  'Nightmare',
  'Lucid',
  'Recurring',
  'Problem-Solving',
  'Flying',
  'Falling',
  'Prophetic',
  'Adventure',
  'Romantic',
  'Emotional',
  'Strange',
  'Funny',
  'Tragedy',
  'Other',
];

Stream<QuerySnapshot> _dreamsStream() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  var col = FirebaseFirestore.instance
    .collection('dreams')
    .where('userId', isEqualTo: uid);

  if (_selectedTags.isNotEmpty) {
    // arrayContainsAny lets you match any of the selected genres
    col = col.where('genres', arrayContainsAny: _selectedTags);
  }

  return col
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
final genresList = (data['genres'] as List<dynamic>?)?.cast<String>() ?? ['Other'];
final genresMatch = genresList.any((g) => g.toLowerCase().contains(kw));

    // 3️⃣ now lookup title/description off the same map
    final t = (data['title']       as String).toLowerCase();
    final b = (data['description'] as String).toLowerCase();
      return t.contains(kw) || b.contains(kw) || genresMatch;
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
            child:  DreamForm(
              titleCtl:      _titleController,
              descCtl:       _descController,
              genres:        _genreOptions,
              initialRating: 5,  // or pull from existing doc when editing
              initialDate: DateTime.now(),
              onSubmit: (selectedGenres, recallRating, selectedDate) async {
                final t = _titleController.text.trim();
                final d = _descController.text.trim();
                if (t.isEmpty || d.isEmpty) return;
                    await FirestoreService().saveDream(
                      title: t,
                      description: d,
                      genres: selectedGenres,       // pass the List<String>
                      recallRating: recallRating,
                      date: selectedDate,
                    );
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

void _showDreamDetail(QueryDocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final genresList = data.containsKey('genres')
      ? (data['genres'] as List).cast<String>()
      : [(data['genre'] as String?) ?? 'Other'];
  final ts = (data['timestamp'] as Timestamp).toDate();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        // <-- Simple title
        title: Text(data['title'] as String),

        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat.yMMMd().format(ts)),
              const SizedBox(height: 8),
              Text(data['description'] as String),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: genresList.map((t) => Chip(label: Text(t))).toList(),
              ),
              const SizedBox(height: 12),
              Text('Recall: ${(data['recallRating'] as num?)?.toInt() ?? 0}/10'),
            ],
          ),
        ),

        // <-- Bottom action buttons, including “Edit”
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
            onPressed: () {
              Navigator.of(context).pop(); // close detail dialog
              _editDream(doc);             // open edit form
            },
          ),
        ],
      );
    },
  );
}



  void _editDream(QueryDocumentSnapshot doc) {
    _titleController.text = doc['title'];
    _descController.text  = doc['description'];
final data = doc.data() as Map<String, dynamic>;
final existingGenres = data.containsKey('genres')
    // new schema: a list
    ? (data['genres'] as List).cast<String>()
    // old schema: single string
    : [ (data['genre'] as String?) ?? 'Other' ];
    final existingRecall   = (doc['recallRating'] as num?)?.toInt() ?? 5;
    final ts = (doc['timestamp'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Dream'),
           content: DreamForm(
          titleCtl:      _titleController,
          descCtl:       _descController,
          initialGenres:  existingGenres,
          genres:        _genreOptions,
          initialRating: existingRecall, 
          initialDate:   ts,     
          onSubmit: (selectedGenres, recallRating, selectedDate) async {
            final t = _titleController.text.trim();
            final d = _descController.text.trim();
            if (t.isEmpty || d.isEmpty) return;

            await FirestoreService().saveDream(
              title:        t,
              description:  d,
              genres:       selectedGenres,
              recallRating: recallRating,
              date:         selectedDate,  
            );

            Navigator.of(context).pop();
            _scrollToBottom();
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
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        // 1) Expanded search field
        Expanded(
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
        ),

        // 2) Filter button
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter by genre',
          onPressed: _showGenreFilterSheet,
        ),
      ],
    ),
  );
}

void _showGenreFilterSheet() {
  showModalBottomSheet<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Filter by genre',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _genreOptions.map((tag) {
                  final isOn = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isOn,
                    onSelected: (on) {
                      // 1) Update the sheet UI
                      setModalState(() {
                        if (on) _selectedTags.add(tag);
                        else   _selectedTags.remove(tag);
                      });
                      // 2) And immediately re-filter the main list
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Dream-Analytics pager ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 240,
              child: DreamChartPager(
                charts: const [
                  DreamGenrePieChart(),
                  DreamSentimentLineChart(),
                ],
              ),
            ),
          ),

          // ── Search bar ──
          _buildSearchBar(),

          // ── Dreams list ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _dreamsStream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  // Print the full error (with index-creation URL) to the console:
                  debugPrint('Firestore query failed: ${snap.error}');
                  // Show a simpler message in the UI:
                  return Center(child: Text('Failed to load dreams (see console)'));
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
                    final data = doc.data() as Map<String, dynamic>;
                    final ts = (data['timestamp'] as Timestamp).toDate();
                    final genresList = data.containsKey('genres')
                        ? (data['genres'] as List).cast<String>()
                        : [ (data['genre'] as String?) ?? 'Other' ];
                    final recallRating =
                        (data['recallRating'] as num?)?.toInt() ?? 0;

                    return Dismissible(
                      key: Key(doc.id),
                      background: Container(color: Colors.red),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _deleteDream(doc.id),
                      child: DreamEntryCard(
                        title: data['title'] as String,
                        date: ts,
                        description: data['description'] as String,
                        tags: genresList,
                        recallRating: recallRating,
                        onTap: () => _showDreamDetail(doc),
                        onShare: () {},
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
