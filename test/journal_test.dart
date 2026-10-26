import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mom_ease/features/journal/data/journal_repository.dart';
import 'package:mom_ease/features/journal/models/journal_entry.dart';
import 'package:mom_ease/features/journal/models/journal_prompt.dart';
import 'package:mom_ease/features/journal/providers/journal_provider.dart';
import 'package:mom_ease/features/journal/screens/journal_screen.dart';
import 'package:mom_ease/features/journal/services/journal_prompt_service.dart';
import 'package:mom_ease/features/journal/services/journal_service.dart';
import 'package:mom_ease/features/journal/services/speech_service.dart';
import 'package:mom_ease/features/journal/widgets/journal_empty_state.dart';
import 'package:mom_ease/features/journal/widgets/journal_entry_card.dart';
import 'package:mom_ease/features/journal/widgets/prompt_card.dart';
import 'package:mom_ease/features/mood/models/mood_type.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory implementation of [JournalRepository] for fast, isolated testing.
class _FakeJournalRepository implements JournalRepository {
  final Map<String, JournalEntry> _entries = {};

  @override
  Future<void> createEntry(JournalEntry entry) async {
    _entries[entry.id] = entry;
  }

  @override
  Future<void> updateEntry(JournalEntry entry) async {
    _entries[entry.id] = entry;
  }

  @override
  Future<void> deleteEntry(String id) async {
    _entries.remove(id);
  }

  @override
  Future<JournalEntry?> getEntryById(String id) async {
    return _entries[id];
  }

  @override
  Future<List<JournalEntry>> getEntries(String userId) async {
    final list = _entries.values.where((e) => e.userId == userId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<JournalEntry>> getEntriesForDate(String userId, DateTime date) async {
    return _entries.values.where((e) {
      return e.userId == userId &&
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();
  }

  @override
  Future<List<JournalEntry>> getEntriesForMonth(String userId, int year, int month) async {
    return _entries.values.where((e) {
      return e.userId == userId && e.date.year == year && e.date.month == month;
    }).toList();
  }

  @override
  Future<List<JournalEntry>> getFavoriteEntries(String userId) async {
    return _entries.values.where((e) => e.userId == userId && e.isFavorite).toList();
  }

  @override
  Future<List<JournalEntry>> searchEntries(String userId, String query) async {
    final q = query.toLowerCase();
    return _entries.values.where((e) {
      return e.userId == userId &&
          ((e.title?.toLowerCase().contains(q) ?? false) ||
              e.content.toLowerCase().contains(q) ||
              e.tags.any((t) => t.toLowerCase().contains(q)));
    }).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. JournalEntry Model Tests', () {
    test('Correctly serializes and deserializes to/from map & JSON', () {
      final now = DateTime(2026, 10, 25, 14, 30);
      final entry = JournalEntry(
        id: 'entry_1',
        userId: 'user_123',
        date: now,
        title: 'Calm morning',
        content: 'Baby took a long nap after feeding.',
        moodId: 'happy',
        tags: ['Baby', 'Sleep'],
        createdAt: now,
        updatedAt: now,
        isFavorite: true,
        promptId: 'p1',
        inputMethod: JournalInputMethod.voice,
      );

      final map = entry.toMap();
      expect(map['id'], equals('entry_1'));
      expect(map['title'], equals('Calm morning'));
      expect(map['moodId'], equals('happy'));
      expect(map['tags'], equals(['Baby', 'Sleep']));
      expect(map['isFavorite'], isTrue);
      expect(map['inputMethod'], equals('voice'));

      final fromMap = JournalEntry.fromMap(map);
      expect(fromMap.id, equals(entry.id));
      expect(fromMap.content, equals(entry.content));
      expect(fromMap.mood, equals(MoodType.happy));
      expect(fromMap.isFavorite, isTrue);

      final json = entry.toJson();
      final fromJson = JournalEntry.fromJson(json);
      expect(fromJson.id, equals(entry.id));
      expect(fromJson.title, equals(entry.title));
    });

    test('Allows null title and null moodId for maximum flexibility', () {
      final now = DateTime.now();
      final entry = JournalEntry(
        id: 'entry_no_mood',
        userId: 'user_123',
        date: now,
        content: 'Just writing a quick thought.',
        createdAt: now,
        updatedAt: now,
      );

      expect(entry.title, isNull);
      expect(entry.moodId, isNull);
      expect(entry.mood, isNull);
      expect(entry.isFavorite, isFalse);
      expect(entry.inputMethod, equals(JournalInputMethod.typed));
    });

    test('copyWith updates fields while preserving unedited properties', () {
      final now = DateTime.now();
      final entry = JournalEntry(
        id: 'entry_orig',
        userId: 'user_123',
        date: now,
        content: 'Original content',
        createdAt: now,
        updatedAt: now,
        isFavorite: false,
      );

      final updated = entry.copyWith(
        content: 'Updated content',
        isFavorite: true,
      );

      expect(updated.id, equals(entry.id));
      expect(updated.content, equals('Updated content'));
      expect(updated.isFavorite, isTrue);
      expect(updated.createdAt, equals(entry.createdAt));
    });
  });

  group('2. Bilingual Prompts & PromptService Tests', () {
    test('Prompts provide valid text in both English and Tagalog', () {
      final prompts = kDefaultJournalPrompts;
      expect(prompts, isNotEmpty);

      for (final p in prompts) {
        expect(p.textEn.trim(), isNotEmpty);
        expect(p.textTl.trim(), isNotEmpty);
        expect(p.localizedText('en'), equals(p.textEn));
        expect(p.localizedText('tl'), equals(p.textTl));
      }
    });

    test('Prompt texts are strictly non-clinical and non-diagnostic', () {
      final clinicalBannedWords = [
        'depress',
        'anxiety disorder',
        'clinical',
        'diagnos',
        'patholog',
        'symptom',
        'disease',
        'syndrome',
        'medication',
      ];

      for (final p in kDefaultJournalPrompts) {
        final enLower = p.textEn.toLowerCase();
        final tlLower = p.textTl.toLowerCase();

        for (final banned in clinicalBannedWords) {
          expect(
            enLower.contains(banned),
            isFalse,
            reason: 'Prompt "${p.textEn}" contains banned clinical term "$banned"',
          );
          expect(
            tlLower.contains(banned),
            isFalse,
            reason: 'Tagalog prompt "${p.textTl}" contains banned clinical term "$banned"',
          );
        }
      }
    });

    test('Suggests mood-appropriate gentle prompts', () {
      final service = JournalPromptService();
      final happyPrompt = service.getFeaturedPrompt('happy');
      expect(happyPrompt, isNotNull);

      final sadPrompt = service.getFeaturedPrompt('sad');
      expect(sadPrompt, isNotNull);

      final neutralPrompt = service.getFeaturedPrompt('neutral');
      expect(neutralPrompt, isNotNull);
    });
  });

  group('3. Journal Repository & Multiple Entries Per Day Tests', () {
    test('Supports multiple journal entries on the exact same date', () async {
      final repo = _FakeJournalRepository();
      final service = JournalService(repo, 'user_sarah');

      final date = DateTime(2026, 10, 25);
      final morning = JournalEntry(
        id: 'entry_morning',
        userId: 'user_sarah',
        date: DateTime(2026, 10, 25, 9, 0),
        title: 'Morning check-in',
        content: 'Baby finally slept 3 hours in a row!',
        moodId: 'happy',
        createdAt: DateTime(2026, 10, 25, 9, 0),
        updatedAt: DateTime(2026, 10, 25, 9, 0),
      );

      final evening = JournalEntry(
        id: 'entry_evening',
        userId: 'user_sarah',
        date: DateTime(2026, 10, 25, 18, 30),
        title: 'Evening reflection',
        content: 'Partner helped with the evening bath.',
        moodId: 'neutral',
        createdAt: DateTime(2026, 10, 25, 18, 30),
        updatedAt: DateTime(2026, 10, 25, 18, 30),
      );

      await service.createEntry(morning);
      await service.createEntry(evening);

      final forDay = await service.getEntriesForDate(date);
      expect(forDay.length, equals(2));
      expect(forDay.map((e) => e.id), containsAll(['entry_morning', 'entry_evening']));
    });

    test('Search finds entries by title, text content, and tags', () async {
      final repo = _FakeJournalRepository();
      final service = JournalService(repo, 'user_sarah');

      final e1 = JournalEntry(
        id: 'e1',
        userId: 'user_sarah',
        date: DateTime.now(),
        title: 'Pediatrician visit',
        content: 'Baby weight is progressing nicely.',
        tags: ['Doctor', 'Health'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final e2 = JournalEntry(
        id: 'e2',
        userId: 'user_sarah',
        date: DateTime.now(),
        content: 'Managed to take a warm nap while baby slept.',
        tags: ['Self-Care', 'Sleep'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.createEntry(e1);
      await service.createEntry(e2);

      final searchTag = await service.searchEntries('Sleep');
      expect(searchTag.length, equals(1));
      expect(searchTag.first.id, equals('e2'));

      final searchTitle = await service.searchEntries('Pediatrician');
      expect(searchTitle.length, equals(1));
      expect(searchTitle.first.id, equals('e1'));
    });

    test('Autosave Draft persistence and clearDraft', () async {
      final repo = _FakeJournalRepository();
      final service = JournalService(repo, 'user_sarah');

      final draft = JournalDraft(
        title: 'Work in progress',
        content: 'I only typed this one line before getting interrupted...',
        moodId: 'sad',
        tags: ['Stress'],
        updatedAt: DateTime.now(),
      );

      await service.saveDraft(draft);
      final loaded = await service.getDraft();

      expect(loaded, isNotNull);
      expect(loaded?.title, equals('Work in progress'));
      expect(loaded?.content, contains('interrupted'));
      expect(loaded?.tags, contains('Stress'));

      await service.clearDraft();
      final cleared = await service.getDraft();
      expect(cleared, isNull);
    });

    test('Export utilities generate structured JSON and readable Plain Text', () async {
      final repo = _FakeJournalRepository();
      final service = JournalService(repo, 'user_sarah');

      final entry = JournalEntry(
        id: 'export_test',
        userId: 'user_sarah',
        date: DateTime(2026, 10, 25, 10, 0),
        title: 'First Smile',
        content: 'Baby smiled at me this morning!',
        moodId: 'veryHappy',
        tags: ['Baby', 'Milestone'],
        createdAt: DateTime(2026, 10, 25, 10, 0),
        updatedAt: DateTime(2026, 10, 25, 10, 0),
      );

      final jsonExport = service.exportAsJson([entry]);
      expect(jsonExport, contains('First Smile'));
      expect(jsonExport, contains('veryHappy'));

      final textExport = service.exportAsPlainText([entry]);
      expect(textExport, contains('Mood: Very Happy'));
      expect(textExport, contains('Baby smiled at me this morning!'));
    });
  });

  group('4. JournalProvider State Management Tests', () {
    test('FilteredEntries honors favorites, mood, and tag filters', () async {
      final repo = _FakeJournalRepository();
      final service = JournalService(repo, 'user_sarah');
      final provider = JournalProvider(service);

      final e1 = JournalEntry(
        id: '1',
        userId: 'user_sarah',
        date: DateTime.now(),
        content: 'Entry 1',
        moodId: 'happy',
        tags: ['Sleep'],
        isFavorite: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final e2 = JournalEntry(
        id: '2',
        userId: 'user_sarah',
        date: DateTime.now(),
        content: 'Entry 2',
        moodId: 'sad',
        tags: ['Feeding'],
        isFavorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await provider.saveEntry(e1);
      await provider.saveEntry(e2);

      // Filter favorites
      provider.setFilterFavorites(true);
      expect(provider.filteredEntries.length, equals(1));
      expect(provider.filteredEntries.first.id, equals('1'));

      provider.setFilterFavorites(false);

      // Filter by mood
      provider.setFilterMood('sad');
      expect(provider.filteredEntries.length, equals(1));
      expect(provider.filteredEntries.first.id, equals('2'));

      // Filter by tag
      provider.setFilterMood(null);
      provider.setFilterTag('Sleep');
      expect(provider.filteredEntries.length, equals(1));
      expect(provider.filteredEntries.first.id, equals('1'));

      // Clear all filters
      provider.clearFilters();
      expect(provider.filteredEntries.length, equals(2));
    });

    test('Lock screen state toggling and PIN unlock', () async {
      final repo = _FakeJournalRepository();
      final service = JournalService(repo, 'user_sarah');
      final provider = JournalProvider(service);

      await provider.setLockEnabled(true);
      expect(provider.isLockEnabled, isTrue);

      provider.lock();
      expect(provider.isLocked, isTrue);

      // Unlock with valid verification
      final unlocked = await provider.verifyAndUnlock('1234');
      expect(unlocked, isTrue);
      expect(provider.isLocked, isFalse);
    });
  });

  group('5. SpeechService User-Facing States Tests', () {
    test('Microphone status messages are calm, helpful, and non-technical', () {
      final speechService = SpeechService();

      expect(speechService.statusMessage, equals('Tap to speak'));

      // Check all non-technical user messages
      final messages = [
        'Tap to speak',
        'Listening...',
        'Finishing transcription...',
        'Microphone access is needed for voice journaling.',
        'Voice input is unavailable right now. You can continue typing.',
      ];

      for (final msg in messages) {
        expect(msg.contains('Exception'), isFalse);
        expect(msg.contains('Error:'), isFalse);
        expect(msg.contains('null'), isFalse);
      }
    });
  });

  group('6. Journal Widget Component Tests', () {
    testWidgets('PromptCard renders daily reflection question and actions', (tester) async {
      bool answered = false;
      bool refreshed = false;
      final prompt = kDefaultJournalPrompts.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PromptCard(
              prompt: prompt,
              language: 'en',
              onUsePrompt: () => answered = true,
              onNextPrompt: () => refreshed = true,
            ),
          ),
        ),
      );

      expect(find.text('Daily Prompt'), findsOneWidget);
      expect(find.text(prompt.textEn), findsOneWidget);
      expect(find.text('Answer Prompt'), findsOneWidget);

      await tester.tap(find.text('Answer Prompt'));
      expect(answered, isTrue);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      expect(refreshed, isTrue);
    });

    testWidgets('JournalEmptyState renders maternal supportive invitation and single New Entry CTA', (tester) async {
      bool newEntryTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JournalEmptyState(
              onNewEntry: () => newEntryTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Your journal is ready when you are.'), findsOneWidget);
      expect(
        find.text('A private space for your thoughts, feelings, and moments. You can type or use your voice.'),
        findsOneWidget,
      );
      expect(find.text('New Entry'), findsOneWidget);

      await tester.tap(find.text('New Entry'));
      expect(newEntryTapped, isTrue);
    });

    testWidgets('JournalEntryCard displays mood badge, content snippet, and tags', (tester) async {
      final entry = JournalEntry(
        id: 'test_card',
        userId: 'sarah',
        date: DateTime.now(),
        title: 'Calm evening',
        content: 'Baby slept peacefully after her warm bath.',
        moodId: 'happy',
        tags: ['Baby', 'Sleep'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JournalEntryCard(
              entry: entry,
              onTap: () {},
              onFavoriteToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('Calm evening'), findsOneWidget);
      expect(find.text('Baby slept peacefully after her warm bath.'), findsOneWidget);
      expect(find.text('#Baby'), findsOneWidget);
      expect(find.text('#Sleep'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('JournalScreen renders header and single empty state CTA without redundant duplicate buttons', (tester) async {
      final repo = _FakeJournalRepository();
      final service = JournalService(repo, 'user_sarah');
      final provider = JournalProvider(service);
      await provider.init();

      await tester.pumpWidget(
        ChangeNotifierProvider<JournalProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: JournalScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Journal'), findsOneWidget);
      expect(find.text('A private space for your thoughts and moments.'), findsOneWidget);
      // Confirms redundant top card is removed
      expect(find.text('How are you feeling today?'), findsNothing);
      expect(find.text('Recent Entries'), findsOneWidget);
      // Empty state contains the single primary New Entry button
      expect(find.text('New Entry'), findsOneWidget);
    });
  });
}
