import 'package:hive/hive.dart';
import '../models/journal_entry.dart';
import 'journal_repository.dart';

/// Local offline Hive implementation of [JournalRepository].
class LocalJournalRepository implements JournalRepository {
  static const String boxName = 'journalBox';

  Box<JournalEntry> get _box => Hive.box<JournalEntry>(boxName);
 
  /// Checks whether an entry belongs to the querying user.
  /// Handles fallback and migration between generic 'local_user' and specific local user IDs.
  bool _matchesUser(String entryUserId, String queryUserId) {
    if (entryUserId == queryUserId) return true;
    final isEntryLocal =
        entryUserId == 'local_user' || entryUserId.startsWith('local_');
    final isQueryLocal =
        queryUserId == 'local_user' || queryUserId.startsWith('local_');
    return isEntryLocal && isQueryLocal;
  }

  @override
  Future<void> createEntry(JournalEntry entry) async {
    await _box.put(entry.id, entry);
  }

  @override
  Future<void> updateEntry(JournalEntry entry) async {
    await _box.put(entry.id, entry);
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
  }

  @override
  Future<JournalEntry?> getEntryById(String id) async {
    return _box.get(id);
  }

  @override
  Future<List<JournalEntry>> getEntries(String userId) async {
    final list = <JournalEntry>[];
    for (final e in _box.values) {
      if (_matchesUser(e.userId, userId)) {
        if (e.userId != userId && userId != 'local_user') {
          // Auto-heal legacy or default 'local_user' entries to active local userId
          e.userId = userId;
          await e.save();
        }
        list.add(e);
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<JournalEntry>> getEntriesForDate(
      String userId, DateTime date) async {
    final list = _box.values.where((e) {
      return _matchesUser(e.userId, userId) &&
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<JournalEntry>> getEntriesForMonth(
      String userId, int year, int month) async {
    final list = _box.values.where((e) {
      return _matchesUser(e.userId, userId) &&
          e.date.year == year &&
          e.date.month == month;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<JournalEntry>> searchEntries(String userId, String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return getEntries(userId);

    final list = _box.values.where((e) {
      if (!_matchesUser(e.userId, userId)) return false;
      final matchTitle = e.title?.toLowerCase().contains(trimmed) ?? false;
      final matchContent = e.content.toLowerCase().contains(trimmed);
      final matchTags = e.tags.any((t) => t.toLowerCase().contains(trimmed));
      return matchTitle || matchContent || matchTags;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return list;
  }

  @override
  Future<List<JournalEntry>> getFavoriteEntries(String userId) async {
    final list = _box.values
        .where((e) => _matchesUser(e.userId, userId) && e.isFavorite)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
