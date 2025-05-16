import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dream_entry_card.dart';

/// A swipeable pager for a single day’s dreams.
class DayDreamPager extends StatefulWidget {
  final List<QueryDocumentSnapshot> entries;
  final void Function(QueryDocumentSnapshot) onTapEntry;
  final void Function(QueryDocumentSnapshot) onEditEntry;
  final void Function(String) onDeleteEntry;

  const DayDreamPager({
    Key? key,
    required this.entries,
    required this.onTapEntry,
    required this.onEditEntry,
    required this.onDeleteEntry,
  }) : super(key: key);

  @override
  _DayDreamPagerState createState() => _DayDreamPagerState();
}

class _DayDreamPagerState extends State<DayDreamPager> {
  late final PageController _ctrl;
  int _curPage = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: entries.length,
            onPageChanged: (p) => setState(() => _curPage = p),
            itemBuilder: (ctx, i) {
              final doc  = entries[i];
              final data = doc.data() as Map<String, dynamic>;
              final ts   = (data['timestamp'] as Timestamp).toDate();
              final tags = data.containsKey('genres')
                  ? (data['genres'] as List).cast<String>()
                  : [(data['genre'] as String?) ?? 'Other'];
              final recall = (data['recallRating'] as num?)?.toInt() ?? 0;

              return DreamEntryCard(
                title:        data['title'] as String,
                description:  data['description'] as String,
                tags:         tags,
                recallRating: recall,
                onTap:        () => widget.onTapEntry(doc),
                onEdit:       () => widget.onEditEntry(doc),
                onDelete:     () => widget.onDeleteEntry(doc.id),
                onPrev: _curPage > 0
                  ? () => _ctrl.previousPage(
                        duration: const Duration(milliseconds:300),
                        curve: Curves.easeOut,
                      )
                  : null,
                onNext: _curPage < entries.length - 1
                  ? () => _ctrl.nextPage(
                        duration: const Duration(milliseconds:300),
                        curve: Curves.easeOut,
                      )
                  : null,
                currentPage: _curPage + 1,
                totalPages: entries.length,
              );
            },
          ),
        ),
      ],
    );
  }
}
