import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A reusable form widget for adding/editing dreams with up to 2 genre tags.
class DreamForm extends StatefulWidget {
  final TextEditingController titleCtl;
  final TextEditingController descCtl;
  final List<String> genres;
  final List<String>? initialGenres;
  final int? initialRating;
  final DateTime? initialDate;
  final void Function(List<String> genres, int recallRating, DateTime date) onSubmit;
  final bool hideActions;

  const DreamForm({
    Key? key,
    required this.titleCtl,
    required this.descCtl,
    required this.genres,
    this.initialGenres,
    this.initialRating,
    this.initialDate,
    required this.onSubmit,
    this.hideActions = false,
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
            widget.onSubmit(_selectedGenres, _recallRating, _selectedDate);
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
                  if (picked != null) setState(() => _selectedDate = picked);
                  widget.onSubmit(_selectedGenres, _recallRating, _selectedDate);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Genres (up to 2)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          _buildGenreChips(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Recall: $_recallRating'),
              Expanded(
                child: Slider(
                  value: _recallRating.toDouble(),
                  min: 0, max: 10, divisions: 10,
                  label: '$_recallRating',
        onChanged: (v) {
          final newVal = v.round();
          setState(() => _recallRating = newVal);
          widget.onSubmit(_selectedGenres, _recallRating, _selectedDate);
                 },
                ),
              ),
            ],
          ),
          if (!widget.hideActions) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed: _selectedGenres.isEmpty
                      ? null
                      : () => widget.onSubmit(_selectedGenres, _recallRating, _selectedDate),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
