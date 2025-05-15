import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firestore_service.dart';
import '../widgets/dream_entry_card.dart';
import '../widgets/dream_chart_pager.dart';
import '../widgets/dream_form.dart';
import '../widgets/multi_dream_entry_modal.dart';


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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      final h = MediaQuery.of(context).size.height * 0.9;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom
        ),
        child: Container(
          height: h,
          clipBehavior: Clip.antiAlias,                        // clip the rounded corners
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16)
            ),
          ),
          child: const MultiDreamEntryModal(),
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
StreamBuilder<QuerySnapshot>(
  stream: _dreamsStream(),
  builder: (ctx, snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!snap.hasData || snap.data!.docs.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(child: Text('No dreams to chart')),
      );
    }

    // 1) group docs by day
    final docsByDay = <DateTime, List<QueryDocumentSnapshot>>{};
    for (var d in snap.data!.docs) {
      final ts   = (d['timestamp'] as Timestamp).toDate();
      final day  = DateTime(ts.year, ts.month, ts.day);
      docsByDay.putIfAbsent(day, () => []).add(d);
    }

    // 2) sort days
    final days = docsByDay.keys.toList()..sort();

    // 3) build buckets
    final buckets = days.map((day) {
      final list = docsByDay[day]!;
      // totalCount
      final totalCount = list.length;
      // genreCounts, recallRatings, wordCounts
      final genreCounts   = <String,int>{};
      final recallRatings = <int>[];
      final wordCounts    = <int>[];

for (var doc in list) {
  final data = doc.data() as Map<String,dynamic>;

  // 1) handle missing 'genres'
  final genresList = data.containsKey('genres')
    // new schema: list of strings
    ? (data['genres'] as List).cast<String>()
    // fallback to old 'genre' single string
    : [(data['genre'] as String?) ?? 'Other'];

  for (var g in genresList) {
    genreCounts[g] = (genreCounts[g] ?? 0) + 1;
  }

  // 2) recallRating
  recallRatings.add((data['recallRating'] as num).toInt());

  // 3) word count
  final desc = (data['description'] as String).trim();
  wordCounts.add(desc.isEmpty
      ? 0
      : desc.split(RegExp(r'\s+')).length
  );
}


      return {
        'date':          day,
        'totalCount':    totalCount,
        'genreCounts':   genreCounts,
        'recallRatings': recallRatings,
        'wordCounts':    wordCounts,
      };
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 400,
        child: DreamChartPager(
          buckets: buckets,
          days: days,
        ),
      ),
    );
  },
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
