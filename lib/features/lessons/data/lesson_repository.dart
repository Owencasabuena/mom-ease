import '../models/lesson.dart';

/// Abstract contract for loading lesson content.
///
/// Designed to be decoupled from the persistence mechanism so that
/// remote sources (such as Firebase) can be plugged in later without
/// changing the service or UI layers.
abstract class LessonRepository {
  /// Loads and returns all available lessons.
  Future<List<Lesson>> getAllLessons();

  /// Retrieves a specific lesson by its unique identifier.
  Future<Lesson?> getLessonById(String id);

  /// Filters lessons by category key (e.g. 'self-care', 'recovery').
  Future<List<Lesson>> getLessonsByCategory(String category);

  /// Filters lessons by matching mood tag.
  Future<List<Lesson>> getLessonsByMood(String moodTag);

  /// Searches lessons by matching title, description, content, or tags.
  Future<List<Lesson>> searchLessons(String query, {String lang = 'en'});
}
