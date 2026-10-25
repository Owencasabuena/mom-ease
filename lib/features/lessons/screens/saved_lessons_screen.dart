import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../widgets/lesson_card.dart';
import 'lesson_detail_screen.dart';

/// Screen listing only lessons that the mother has bookmarked.
class SavedLessonsScreen extends StatelessWidget {
  const SavedLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lessonProvider = context.watch<LessonProvider>();
    final theme = Theme.of(context);
    final lang = lessonProvider.currentLanguage;
    final isTl = lang == 'tl';
    final saved = lessonProvider.bookmarkedLessons;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTl ? 'Mga Nai-save na Aralin' : 'Saved Lessons',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: saved.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 64,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isTl
                          ? 'Wala pang nai-save na aralin'
                          : 'No saved lessons yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTl
                          ? 'Pindutin ang bookmark icon sa anumang aralin upang madali mo itong mahanap muli dito.'
                          : 'Tap the bookmark icon on any lesson so you can easily revisit it here anytime.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: saved.length,
              itemBuilder: (context, index) {
                final lesson = saved[index];
                final isCompleted =
                    lessonProvider.completedIds.contains(lesson.id);

                return LessonCard(
                  lesson: lesson,
                  language: lang,
                  isBookmarked: true,
                  isCompleted: isCompleted,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LessonDetailScreen(lesson: lesson),
                      ),
                    );
                  },
                  onToggleBookmark: () {
                    lessonProvider.toggleBookmark(lesson.id);
                  },
                );
              },
            ),
    );
  }
}
