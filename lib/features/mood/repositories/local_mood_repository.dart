import 'package:hive/hive.dart';

import '../models/mood_entry.dart';
import '../models/mood_type.dart';
import 'mood_repository.dart';

/// Offline-first Hive implementation of [MoodRepository].
class LocalMoodRepository implements MoodRepository {
  static const String _boxName = 'moodBox';

  Box<MoodEntry> get _box => Hive.box<MoodEntry>(_boxName);

  // ── Key helpers ─────────────────────────────────────────────────────────────

  String _key(String userId, DateTime date) =>
      '${userId}_${date.year}_${date.month}_${date.day}';

  /// Strips hours/minutes/seconds to ensure one entry per calendar day.
  DateTime _normalise(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // ── Read ─────────────────────────────────────────────────────────────────────

  @override
  Future<MoodEntry?> getMoodForDate(String userId, DateTime date) async {
    return _box.get(_key(userId, date));
  }

  @override
  Future<List<MoodEntry>> getMoodsForMonth(
    String userId,
    int year,
    int month,
  ) async {
    return _box.values.where((e) {
      return e.userId == userId && e.date.year == year && e.date.month == month;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<List<MoodEntry>> getRecentMoods(String userId, {int days = 7}) async {
    final cutoff = _normalise(DateTime.now())
        .subtract(Duration(days: days - 1));
    return _box.values
        .where((e) => e.userId == userId && !e.date.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<Map<MoodType, int>> getMoodCountsForMonth(
    String userId,
    int year,
    int month,
  ) async {
    final entries = await getMoodsForMonth(userId, year, month);
    final counts = <MoodType, int>{for (final m in MoodType.values) m: 0};
    for (final e in entries) {
      counts[e.mood] = (counts[e.mood] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<bool> hasMoodForDate(String userId, DateTime date) async =>
      _box.containsKey(_key(userId, date));

  // ── Write ────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveMood(MoodEntry entry) async {
    final key = _key(entry.userId, entry.date);
    final normalised = entry.copyWith(updatedAt: entry.createdAt)
      ..date = _normalise(entry.date);
    await _box.put(key, normalised);
  }

  @override
  Future<void> updateMood(MoodEntry entry) async {
    final key = _key(entry.userId, entry.date);
    final updated = entry.copyWith(updatedAt: DateTime.now());
    await _box.put(key, updated);
  }

  @override
  Future<void> deleteMood(String userId, DateTime date) async {
    await _box.delete(_key(userId, date));
  }
}
