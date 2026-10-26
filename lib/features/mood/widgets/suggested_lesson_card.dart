import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../lessons/models/lesson.dart';
import '../../lessons/providers/lesson_provider.dart';
import '../../lessons/screens/lesson_detail_screen.dart';
import '../../lessons/services/lesson_recommendation_service.dart';
import '../models/mood_type.dart';
import '../state/mood_provider.dart';

class SuggestedLessonCard extends StatelessWidget {
  const SuggestedLessonCard({super.key});

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

  @override
  Widget build(BuildContext context) {
    final mood = context.watch<MoodProvider>();
    final lessonProvider = Provider.of<LessonProvider?>(context);
    final theme = Theme.of(context);
    final lang = lessonProvider?.currentLanguage ?? 'en';
    final isTl = lang == 'tl';

    // Pick active mood: selectedEntry takes priority, then most recent in month
    final currentMood =
        mood.selectedEntry?.mood ??
        (mood.monthEntries.isNotEmpty ? mood.monthEntries.last.mood : null);

    Lesson? recommendedLesson;
    if (lessonProvider != null && lessonProvider.allLessons.isNotEmpty) {
      recommendedLesson = LessonRecommendationService().getRecommendation(
        allLessons: lessonProvider.allLessons,
        moodId: currentMood?.name,
        completedIds: lessonProvider.completedIds,
      );
    }

    final lessonColor = currentMood?.color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isTl ? 'Mungkahing Aralin' : 'Suggested for you',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (currentMood != null && recommendedLesson != null)
                Text(
                  isTl ? 'Batay sa iyong check-in' : 'Based on your check-in',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (recommendedLesson == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isTl
                    ? 'Magkakaroon kami ng rekomendasyon para sa iyo sa lalong madaling panahon.'
                    : "We'll have a recommendation for you soon.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Card(
              elevation: 0,
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.35,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          LessonDetailScreen(lesson: recommendedLesson!),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon / Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 70,
                          height: 70,
                          color: lessonColor.withValues(alpha: 0.2),
                          child: Icon(
                            _categoryIcon(recommendedLesson.category),
                            color: lessonColor,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recommendedLesson.localizedTitle(lang),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recommendedLesson.localizedDescription(lang),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${recommendedLesson.readingTimeMinutes} min',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => LessonDetailScreen(
                                          lesson: recommendedLesson!,
                                        ),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(isTl ? 'Tingnan' : 'View Lesson'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
