import 'package:flutter/material.dart';
import '../dream_genres.dart';

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
/// A card showing a dream entry, with title, description, genre tags,
/// recall rating, and optional share/edit/delete actions.
/// ─────────────────────────────────────────────────────────────────────────────
class DreamEntryCard extends StatelessWidget {
  final String title;
  final String description;
  final List<String> tags;
  final int recallRating;
  final VoidCallback? onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final int? currentPage;
  final int? totalPages;

  const DreamEntryCard({
    Key? key,
    this.onTap,
    required this.title,
    required this.description,
    this.tags = const [],
    required this.recallRating,
    this.onShare,
    required this.onEdit,
    required this.onDelete,
    this.onAdd,
    this.onPrev,
    this.onNext,
    this.currentPage,
    this.totalPages,
  }) : super(key: key);

  Color _colorForTag(String tag) {
    return genreColors[tag] ?? Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),

        // ─── child must be here inside Card ───────────────────────────────
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: title + recall + (+)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$recallRating/10',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  if (onAdd != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: onAdd,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),
              // ─── Combined bottom bar ──────────────────────────
              Row(
                children: [
                  // 1) Tags on the left
                  if (tags.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags.map((t) {
                          final tagColor = _colorForTag(t);
                          return Chip(
                            label: Text(t, style: TextStyle(color: tagColor.darken(0.3))),
                            backgroundColor: tagColor.withOpacity(0.1),
                            shape: StadiumBorder(
                              side: BorderSide(color: tagColor, width: 1.5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          );
                        }).toList(),
                      ),
                    )
                  else
                    const Spacer(),

                  // 2) Centered arrows + page indicator. Only show when there are actually multiple pages
                  if (currentPage != null && totalPages != null && totalPages! > 1) ...[
                    IconButton(onPressed: onPrev, icon: Icon(Icons.chevron_left)),
                    Text('${currentPage!} of ${totalPages!}'),
                    IconButton(onPressed: onNext, icon: Icon(Icons.chevron_right)),
                  ],
                  // 3) Actions flush right
                  const Spacer(),
                  if (onShare != null)
                    IconButton(icon: const Icon(Icons.share), onPressed: onShare),
                  IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                  IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
