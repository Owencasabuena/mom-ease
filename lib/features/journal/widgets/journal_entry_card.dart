import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../mood/models/mood_type.dart';
import '../models/journal_entry.dart';

class JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const JournalEntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(dt.year, dt.month, dt.day);
    final timeStr = DateFormat('h:mm a').format(dt);

    if (entryDate == today) {
      return 'Today • $timeStr';
    } else if (entryDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday • $timeStr';
    } else if (now.difference(entryDate).inDays < 7) {
      return '${DateFormat('EEEE').format(dt)} • $timeStr';
    } else {
      return '${DateFormat('MMM d, yyyy').format(dt)} • $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = entry.mood;

    final visibleTags = entry.tags.take(3).toList();
    final remainingTagsCount = entry.tags.length - visibleTags.length;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: mood != null
              ? mood.color.withValues(alpha: 0.25)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Mood & Metadata + Favorite Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (mood != null) ...[
                    Image.asset(
                      mood.assetPath,
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.sentiment_satisfied_rounded,
                        size: 20,
                        color: mood.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mood.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: mood.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '•',
                      style: TextStyle(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            _formatDate(entry.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entry.inputMethod == 'voice') ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.mic_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Semantics(
                    label: entry.isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        entry.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: entry.isFavorite
                            ? Colors.amber
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onFavoriteToggle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Optional Title (visually stronger than preview)
              if (entry.title != null && entry.title!.trim().isNotEmpty) ...[
                Text(
                  entry.title!.trim(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],

              // 2-line Content Preview
              Text(
                entry.content.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Tags Row (up to 2-3 tags + optional +N badge)
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...visibleTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#$tag',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }),
                    if (remainingTagsCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+$remainingTagsCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
