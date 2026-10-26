import 'dart:math';

import '../models/journal_prompt.dart';

/// Service providing gentle, non-clinical journaling prompt recommendations.
///
/// Safety Rule: Prompts are never used to diagnose the user or make psychiatric claims.
class JournalPromptService {
  final List<JournalPrompt> _prompts;
  final Random _random;

  JournalPromptService({List<JournalPrompt>? prompts, Random? random})
    : _prompts = prompts ?? kDefaultJournalPrompts,
      _random = random ?? Random();

  List<JournalPrompt> getAllPrompts() => List.unmodifiable(_prompts);

  JournalPrompt? getPromptById(String id) {
    try {
      return _prompts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Returns prompts filtered by [moodId] (e.g. 'happy', 'sad').
  List<JournalPrompt> getPromptsByMood(String? moodId) {
    if (moodId == null || moodId.isEmpty) return getAllPrompts();

    final matches = _prompts
        .where(
          (p) => p.moodTags.any((t) => t.toLowerCase() == moodId.toLowerCase()),
        )
        .toList();

    return matches.isNotEmpty ? matches : getAllPrompts();
  }

  /// Selects a single featured prompt suited for the current mood.
  JournalPrompt getFeaturedPrompt(String? moodId) {
    final pool = getPromptsByMood(moodId);
    if (pool.isEmpty) return _prompts.first;
    return pool[_random.nextInt(pool.length)];
  }

  /// Filters prompts by category (reflection, gratitude, self-care, support, bonding).
  List<JournalPrompt> getPromptsByCategory(String category) {
    if (category.toLowerCase() == 'all') return getAllPrompts();
    return _prompts
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();
  }
}
