import '../models/journal_entry.dart';

/// Abstract contract for journal persistence.
///
/// Decouples local Hive storage from UI and business logic,
/// making future optional sync or export straightforward.
abstract class JournalRepository {
  Future<void> createEntry(JournalEntry entry);

  Future<void> updateEntry(JournalEntry entry);

  Future<void> deleteEntry(String id);

  Future<JournalEntry?> getEntryById(String id);

  /// All entries for [userId], ordered newest first.
  Future<List<JournalEntry>> getEntries(String userId);

  /// Entries written on a specific calendar [date].
  Future<List<JournalEntry>> getEntriesForDate(String userId, DateTime date);

  /// Entries written during [year] and [month].
  Future<List<JournalEntry>> getEntriesForMonth(
      String userId, int year, int month);

  /// Search entries matching title, content, or tags.
  Future<List<JournalEntry>> searchEntries(String userId, String query);

  /// Favorite entries for [userId].
  Future<List<JournalEntry>> getFavoriteEntries(String userId);
}
