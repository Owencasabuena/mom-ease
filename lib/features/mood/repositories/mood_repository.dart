import '../models/mood_entry.dart';
import '../models/mood_type.dart';

/// Abstract contract for mood persistence.
/// Swap LocalMoodRepository with a remote implementation without touching the UI.
abstract class MoodRepository {
  Future<MoodEntry?> getMoodForDate(String userId, DateTime date);
  Future<List<MoodEntry>> getMoodsForMonth(String userId, int year, int month);
  Future<List<MoodEntry>> getRecentMoods(String userId, {int days = 7});
  Future<Map<MoodType, int>> getMoodCountsForMonth(
    String userId,
    int year,
    int month,
  );
  Future<bool> hasMoodForDate(String userId, DateTime date);
  Future<void> saveMood(MoodEntry entry);
  Future<void> updateMood(MoodEntry entry);
  Future<void> deleteMood(String userId, DateTime date);
}
