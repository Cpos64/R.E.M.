import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// A little helper to darken your pastel colors for legible text.
// Extension must live at top‐level.
// ─────────────────────────────────────────────────────────────────────────────
extension ColorUtils on Color {
  /// Darken [this] by [amount] (0.0–1.0).
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final darker = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darker.toColor();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// A card showing a dream entry, with date, title, description, genre tags,
/// and optional share/edit/delete actions.
/// ─────────────────────────────────────────────────────────────────────────────
class DreamEntryCard extends StatelessWidget {
  final DateTime date;
  final String title;
  final String description;
  final List<String> tags;
  final VoidCallback? onShare;   // now nullable
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DreamEntryCard({
    Key? key,
    required this.date,
    required this.title,
    required this.description,
    this.tags = const [],         // default empty
    this.onShare,                 // optional share
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  /// Pick a soft pastel shade based on the tag’s hash.
  Color _colorForTag(String tag) {
    final primaries = Colors.primaries;
    final material = primaries[tag.hashCode % primaries.length];
    return material.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1) Date (small, grey)
              Text(
                DateFormat.yMMMd().format(date),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),

              // 2) Title (single line, ellipsis)
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // 3) Description (up to 3 lines, ellipsis)
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // 4) Genre tags (outlined)
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.map((t) {
                    final tagColor = _colorForTag(t);
                    return Chip(
                      label: Text(
                        t,
                        style: TextStyle(
                          color: tagColor.darken(0.3),
                        ),
                      ),
                      backgroundColor: Colors.transparent,
                      shape: StadiumBorder(
                        side: BorderSide(color: tagColor, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),
              // 5) Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onShare != null) ...[
                    Tooltip(
                      message: 'Share dream',
                      child: IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: onShare,
                      ),
                    ),
                  ],
                  Tooltip(
                    message: 'Edit dream',
                    child: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onEdit,
                    ),
                  ),
                  Tooltip(
                    message: 'Delete dream',
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
