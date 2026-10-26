import 'package:flutter/material.dart';

import '../models/lesson.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final String language;
  final bool isBookmarked;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onToggleBookmark;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.language,
    required this.isBookmarked,
    required this.isCompleted,
    required this.onTap,
    required this.onToggleBookmark,
  });

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'self-care':
        return Icons.spa_rounded;
      case 'recovery':
        return Icons.healing_rounded;
      case 'mental-health':
        return Icons.favorite_border_rounded;
      case 'physical-health':
        return Icons.directions_walk_rounded;
      case 'mother-and-baby':
        return Icons.child_care_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  Color _categoryColor(BuildContext context, String category) {
    final theme = Theme.of(context);
    switch (category) {
      case 'self-care':
        return theme.colorScheme.primary;
      case 'recovery':
        return theme.colorScheme.secondary;
      case 'mental-health':
        return theme.colorScheme.tertiary;
      case 'physical-health':
        return theme.colorScheme.secondary;
      case 'mother-and-baby':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = _categoryColor(context, lesson.category);
    final isTl = language == 'tl';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topic Icon / Thumbnail Box
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      _categoryIcon(lesson.category),
                      color: catColor,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Content details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Duration & Video Tag
                    Row(
                      children: [
                        Text(
                          lesson.categoryLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: catColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' • ${lesson.readingTimeMinutes} min',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (lesson.hasVideo) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 11,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Video',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Title
                    Text(
                      lesson.localizedTitle(language),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Short description
                    Text(
                      lesson.localizedDescription(language),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Completed badge
                    if (isCompleted)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isTl ? 'Natapos na' : 'Completed',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Bookmark toggle button
              IconButton(
                icon: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isBookmarked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark lesson',
                onPressed: onToggleBookmark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
