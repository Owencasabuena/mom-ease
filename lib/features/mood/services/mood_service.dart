import '../models/mood_entry.dart';
import '../models/mood_type.dart';
import '../repositories/mood_repository.dart';

/// Business logic layer for mood tracking.
class MoodService {
  MoodService(this._repo);

  final MoodRepository _repo;

  // ── Safety threshold ─────────────────────────────────────────────────────────

  /// Returns true when the user has logged [threshold] or more very-sad moods
  /// in the past [days] days. Used to show the gentle support banner.
  Future<bool> shouldShowSupportMessage(String userId,
      {int threshold = 3, int days = 7}) async {
    final recent = await _repo.getRecentMoods(userId, days: days);
    final verySadCount =
        recent.where((e) => e.mood == MoodType.verySad).length;
    return verySadCount >= threshold;
  }

  // ── Convenience delegators ───────────────────────────────────────────────────

  Future<MoodEntry?> getMoodForDate(String userId, DateTime date) =>
      _repo.getMoodForDate(userId, date);

  Future<List<MoodEntry>> getMoodsForMonth(
          String userId, int year, int month) =>
      _repo.getMoodsForMonth(userId, year, month);

  Future<Map<MoodType, int>> getMoodCountsForMonth(
          String userId, int year, int month) =>
      _repo.getMoodCountsForMonth(userId, year, month);

  Future<bool> hasMoodForDate(String userId, DateTime date) =>
      _repo.hasMoodForDate(userId, date);

  Future<void> saveMood(MoodEntry entry) => _repo.saveMood(entry);

  Future<void> updateMood(MoodEntry entry) => _repo.updateMood(entry);

  // ── Stats helpers ─────────────────────────────────────────────────────────────

  /// Average mood value for a month; null when no entries exist.
  Future<double?> averageMoodForMonth(
      String userId, int year, int month) async {
    final entries = await _repo.getMoodsForMonth(userId, year, month);
    if (entries.isEmpty) return null;
    final total = entries.fold<int>(0, (sum, e) => sum + e.moodValue);
    return total / entries.length;
  }
}
