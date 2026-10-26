import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../lessons/models/lesson.dart';
import '../../lessons/providers/lesson_provider.dart';
import '../../lessons/screens/lesson_detail_screen.dart';
import '../../lessons/services/lesson_recommendation_service.dart';
import '../../mood/models/mood_type.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../services/journal_prompt_service.dart';
import 'journal_editor_screen.dart';

/// Screen displaying the full content and metadata of a journal entry.
class JournalDetailScreen extends StatelessWidget {
  final JournalEntry entry;

  const JournalDetailScreen({
    super.key,
    required this.entry,
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete journal entry?'),
        content: const Text(
          'This entry will be permanently removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // dismiss dialog
              final provider = context.read<JournalProvider>();
              final success = await provider.deleteEntry(entry.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Journal entry deleted'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.of(context).pop(); // exit detail screen
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not delete entry. Please try again.'),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final journalProvider = context.watch<JournalProvider>();

    // Locate the current version of this entry in the provider in case it was edited or favorited
    final currentEntry = journalProvider.allEntries.firstWhere(
      (e) => e.id == entry.id,
      orElse: () => entry,
    );

    final mood = currentEntry.moodId != null
        ? MoodType.fromId(currentEntry.moodId!)
        : null;

    final prompt = currentEntry.promptId != null
        ? JournalPromptService().getPromptById(currentEntry.promptId!)
        : null;

    final dateFormat = DateFormat('EEEE, MMMM d, y • h:mm a');
    final formattedDate = dateFormat.format(currentEntry.date);

    // Optional lesson suggestion based on linked mood
    final lessonProvider = Provider.of<LessonProvider?>(context);
    final lang = lessonProvider?.currentLanguage ?? 'en';
    final isTl = lang == 'tl';

    Lesson? recommendedLesson;
    if (mood != null &&
        lessonProvider != null &&
        lessonProvider.allLessons.isNotEmpty) {
      recommendedLesson = LessonRecommendationService().getRecommendation(
        allLessons: lessonProvider.allLessons,
        moodId: mood.name,
        completedIds: lessonProvider.completedIds,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entry'),
        actions: [
          IconButton(
            tooltip: currentEntry.isFavorite ? 'Remove from favorites' : 'Add to favorites',
            icon: Icon(
              currentEntry.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: currentEntry.isFavorite ? Colors.amber : null,
            ),
            onPressed: () {
              journalProvider.toggleFavorite(currentEntry.id);
            },
          ),
          IconButton(
            tooltip: 'Edit entry',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JournalEditorScreen(
                    existingEntry: currentEntry,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Delete entry',
            icon: Icon(
              Icons.delete_outline_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and input method header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  formattedDate,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (currentEntry.inputMethod == JournalInputMethod.voice)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Voice',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (currentEntry.inputMethod == JournalInputMethod.mixed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_none_rounded,
                          size: 14,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Voice & typed',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Linked Mood Badge
            if (mood != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: mood.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: mood.color.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mood.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: mood.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Prompt Card (if one was used)
            if (prompt != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Prompt answered',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      prompt.localizedText(lang),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title (optional)
            if (currentEntry.title != null && currentEntry.title!.trim().isNotEmpty) ...[
              Text(
                currentEntry.title!.trim(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Content
            SelectableText(
              currentEntry.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 20),

            // Tags
            if (currentEntry.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: currentEntry.tags.map((tag) {
                  return Chip(
                    label: Text('#$tag'),
                    backgroundColor: theme.colorScheme.surfaceContainerLow,
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    labelStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Metadata: Created & Updated
            Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: 'Created ${DateFormat('MMM d, y h:mm a').format(currentEntry.createdAt)}',
                  ),
                  if (currentEntry.updatedAt.isAfter(currentEntry.createdAt.add(const Duration(seconds: 1)))) ...[
                    const TextSpan(text: '  •  '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        Icons.edit_note_rounded,
                        size: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: 'Edited ${DateFormat('MMM d, y h:mm a').format(currentEntry.updatedAt)}',
                    ),
                  ],
                ],
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            // Post-entry Lesson Suggestion (if linked mood has recommendation)
            Builder(
              builder: (context) {
                final suggested = recommendedLesson;
                if (suggested == null) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    Text(
                      isTl ? 'Maaaring makatulong din sa iyo' : 'You may also find this helpful',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LessonDetailScreen(lesson: suggested),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  color: (mood != null ? mood.color : theme.colorScheme.primary)
                                      .withValues(alpha: 0.2),
                                  child: Icon(
                                    _categoryIcon(suggested.category),
                                    color: mood != null ? mood.color : theme.colorScheme.primary,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      suggested.localizedTitle(lang),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${suggested.readingTimeMinutes} min • ${suggested.category}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
