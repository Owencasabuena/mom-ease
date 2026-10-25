import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mood_type.dart';
import '../state/mood_provider.dart';

/// Placeholder lesson data keyed by mood.
/// Replace this map with a LessonRepository reading assets/data/lessons.json later.
class _Lesson {
  const _Lesson(
      {required this.title, required this.duration, required this.description});
  final String title;
  final String duration;
  final String description;
}

const Map<MoodType, _Lesson> _kLessons = {
  MoodType.veryHappy: _Lesson(
    title: 'Celebrate Your Wins – Big and Small',
    duration: '5 min',
    description: 'Positive wellness habits to maintain your energy.',
  ),
  MoodType.happy: _Lesson(
    title: 'Healthy Postpartum Habits',
    duration: '6 min',
    description: 'Simple routines to keep your wellbeing on track.',
  ),
  MoodType.neutral: _Lesson(
    title: 'General Postpartum Wellness',
    duration: '7 min',
    description: 'A gentle check-in for the in-between days.',
  ),
  MoodType.sad: _Lesson(
    title: 'Gentle Self-Care on Hard Days',
    duration: '5 min',
    description: 'Small acts of kindness you can do for yourself today.',
  ),
  MoodType.verySad: _Lesson(
    title: 'You Are Not Alone',
    duration: '5 min',
    description: 'Finding comfort and support during difficult moments.',
  ),
};

class SuggestedLessonCard extends StatelessWidget {
  const SuggestedLessonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final mood = context.watch<MoodProvider>();
    final theme = Theme.of(context);

    // Pick lesson by most recent mood this month, or default to neutral
    MoodType lessonMood = MoodType.neutral;
    if (mood.selectedEntry != null) {
      lessonMood = mood.selectedEntry!.mood;
    } else if (mood.monthEntries.isNotEmpty) {
      lessonMood = mood.monthEntries.last.mood;
    }

    final lesson = _kLessons[lessonMood]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested for you',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            color: theme.colorScheme.secondaryContainer
                .withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Thumbnail placeholder
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 70,
                      height: 70,
                      color: lessonMood.color.withValues(alpha: 0.25),
                      child: Icon(Icons.play_circle_outline_rounded,
                          color: lessonMood.color, size: 36),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(lesson.duration,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                )),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                // TODO: Navigate to lesson screen when lessons feature is built
                              },
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('View Lesson'),
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
        ],
      ),
    );
  }
}
