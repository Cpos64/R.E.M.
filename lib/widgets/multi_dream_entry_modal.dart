// lib/widgets/multi_dream_entry_modal.dart

import 'package:flutter/material.dart';
import '../firestore_service.dart';
import 'dream_form.dart';
import '../dream_genres.dart';

/// Same genre options as in DreamScreen
const List<String> _genreOptions = dreamGenres;

class MultiDreamEntryModal extends StatefulWidget {
  const MultiDreamEntryModal({Key? key}) : super(key: key);

  @override
  State<MultiDreamEntryModal> createState() => _MultiDreamEntryModalState();
}

class _MultiDreamEntryModalState extends State<MultiDreamEntryModal> {
  static const _maxDreams = 10;
  final List<TextEditingController> _titleCtrls = [];
  final List<TextEditingController> _descCtrls  = [];
  final List<List<String>>        _genreSel    = [];
  final List<int>                 _ratings     = [];
  final List<DateTime>            _dates       = [];

  late final PageController _pageCtrl;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _addDreamForm();
  }

  void _addDreamForm() {
    if (_titleCtrls.length >= _maxDreams) return;

    _titleCtrls.add(TextEditingController());
    _descCtrls.add(TextEditingController());
    _genreSel.add([]);
    _ratings.add(5);
    _dates.add(DateTime.now());

    setState(() {
      // now rebuild; after that's painted, we can animate
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageCtrl.hasClients) {
        _pageCtrl.animateToPage(
          _titleCtrls.length - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveAllDreams() async {
    for (var i = 0; i < _titleCtrls.length; i++) {
      final title = _titleCtrls[i].text.trim();
      final desc  = _descCtrls[i].text.trim();
      if (title.isEmpty || desc.isEmpty) continue;

      await FirestoreService().saveDream(
        title:        title,
        description:  desc,
        genres:       _genreSel[i],
        recallRating: _ratings[i],
        date:         _dates[i],
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // light “card” surface
      backgroundColor: Theme.of(context).colorScheme.surface,

      appBar: AppBar(
        title: const Text('New Dream Log'),
        elevation: 0,
      ),

      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: _titleCtrls.length,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemBuilder: (context, i) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom
                  ),
                  child: DreamForm(
                    key: ValueKey(i),              // <— preserve each page’s state
                    titleCtl:      _titleCtrls[i],
                    descCtl:       _descCtrls[i],
                    genres:        _genreOptions,
                    initialGenres: _genreSel[i],
                    initialRating: _ratings[i],
                    initialDate:   _dates[i],
                    hideActions:   true,           // no individual Save/Cancel
                    onSubmit: (genres, rating, date) {
                      _genreSel[i] = genres;
                      _ratings[i]  = rating;
                      _dates[i]    = date;
                    },
                  ),
                );
              },
            ),
          ),

          // pager indicator under the form
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Dream ${_currentPage + 1} of ${_titleCtrls.length}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),

      // bottom row with Cancel + Save
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const Spacer(),
            TextButton(
              onPressed: _saveAllDreams,
              child: const Text('Save'),
            ),
          ],
        ),
      ),

      // the “+” button to add another draft
      floatingActionButton: _titleCtrls.length < _maxDreams
          ? FloatingActionButton(
              onPressed: _addDreamForm,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (var c in _titleCtrls) c.dispose();
    for (var c in _descCtrls)  c.dispose();
    super.dispose();
  }
}
