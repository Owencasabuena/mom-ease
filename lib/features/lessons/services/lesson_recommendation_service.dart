import 'dart:math';
import '../models/lesson.dart';

/// Recommends supportive postpartum lessons based on current or recent mood.
///
/// Mental health note: This service is purely for gentle, supportive suggestions.
/// It must NEVER diagnose any medical or psychological condition.
class LessonRecommendationService {
  final Random _random;

  LessonRecommendationService({Random? random}) : _random = random ?? Random();

  /// Returns the best recommended [Lesson] for the given [moodId] (e.g. 'veryHappy',
  /// 'happy', 'neutral', 'sad', 'verySad').
  ///
  /// If [moodId] is null or no lessons match, falls back to a safe general lesson
  /// (e.g. 'lesson_002' or 'lesson_001').
  Lesson getRecommendation({
    required List<Lesson> allLessons,
    String? moodId,
    Set<String> completedIds = const {},
    String? lastOpenedId,
  }) {
    if (allLessons.isEmpty) {
      throw StateError('Cannot recommend from an empty lesson catalogue.');
    }

    if (moodId == null || moodId.isEmpty) {
      return _fallbackLesson(allLessons);
    }

    final normalizedMood = moodId.toLowerCase();

    // 1. Filter candidates matching mood in moodTags
    final matches = allLessons.where((lesson) {
      return lesson.moodTags.any((tag) => tag.toLowerCase() == normalizedMood);
    }).toList();

    if (matches.isEmpty) {
      return _fallbackLesson(allLessons);
    }

    // 2. Prefer lessons not yet completed
    final uncompleted =
        matches.where((l) => !completedIds.contains(l.id)).toList();

    final pool = uncompleted.isNotEmpty ? uncompleted : matches;

    // 3. Prefer lessons not just opened
    final freshPool =
        pool.where((l) => lastOpenedId == null || l.id != lastOpenedId).toList();

    final finalPool = freshPool.isNotEmpty ? freshPool : pool;

    return finalPool[_random.nextInt(finalPool.length)];
  }

  /// Safe general lesson fallback when no mood history exists or matches.
  Lesson _fallbackLesson(List<Lesson> allLessons) {
    // Prefer lesson_002 (Understanding Postpartum Recovery) or lesson_001
    final preferred = allLessons.firstWhere(
      (l) => l.id == 'lesson_002',
      orElse: () => allLessons.firstWhere(
        (l) => l.id == 'lesson_001',
        orElse: () => allLessons.first,
      ),
    );
    return preferred;
  }

  /// Gentle supportive recommendation header copy.
  /// Never diagnoses postpartum depression or anxiety.
  String getRecommendationSubheading(String? moodId, String lang) {
    if (lang == 'tl') {
      return 'Maaaring makatulong ito sa iyong nararamdaman.';
    }
    return 'You may find this helpful for where you are today.';
  }
}
