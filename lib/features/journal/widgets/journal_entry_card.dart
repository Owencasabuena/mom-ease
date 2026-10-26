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

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: mood != null
              ? mood.color.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Date + Mood + Favorite
              Row(
                children: [
                  if (mood != null) ...[
                    Image.asset(
                      mood.assetPath,
                      width: 22,
                      height: 22,
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
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      _formatDate(entry.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (entry.inputMethod == 'voice')
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.mic_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      entry.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: entry.isFavorite
                          ? Colors.amber
                          : theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onFavoriteToggle,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title if present
              if (entry.title != null && entry.title!.isNotEmpty) ...[
                Text(
                  entry.title!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],

              // Content snippet
              Text(
                entry.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Tags row
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: entry.tags.take(4).map((tag) {
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
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
