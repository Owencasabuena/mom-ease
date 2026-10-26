import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/storage_service.dart';
import '../../mood/models/mood_type.dart';
import '../data/journal_repository.dart';
import '../models/journal_entry.dart';

/// Representation of an unfinished journal draft.
class JournalDraft {
  final String title;
  final String content;
  final String? moodId;
  final String? promptId;
  final List<String> tags;
  final DateTime updatedAt;

  const JournalDraft({
    this.title = '',
    this.content = '',
    this.moodId,
    this.promptId,
    this.tags = const [],
    required this.updatedAt,
  });

  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;

  Map<String, dynamic> toMap() => {
    'title': title,
    'content': content,
    'moodId': moodId,
    'promptId': promptId,
    'tags': tags,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory JournalDraft.fromMap(Map<String, dynamic> map) => JournalDraft(
    title: map['title'] as String? ?? '',
    content: map['content'] as String? ?? '',
    moodId: map['moodId'] as String?,
    promptId: map['promptId'] as String?,
    tags: List<String>.from(map['tags'] ?? []),
    updatedAt: map['updatedAt'] != null
        ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );

  String toJson() => jsonEncode(toMap());

  factory JournalDraft.fromJson(String json) =>
      JournalDraft.fromMap(jsonDecode(json) as Map<String, dynamic>);
}

/// Service coordinating journal persistence, drafts, tags, and lock preferences.
class JournalService {
  final JournalRepository _repository;
  final String _userId;
  final StorageService? _storageService;

  static const List<String> kDefaultTags = [
    'Baby',
    'Recovery',
    'Sleep',
    'Feeding',
    'Family',
    'Partner',
    'Self-Care',
    'Stress',
    'Happy Moment',
    'Difficult Day',
  ];

  static const String _draftPrefix = 'journal_draft_';
  static const String _customTagsPrefix = 'journal_custom_tags_';
  static const String _lockPrefix = 'journal_lock_enabled_';

  JournalService(
    this._repository, [
    this._userId = 'local_user',
    this._storageService,
  ]);

  String get userId => _userId;

  String get _draftKey => '$_draftPrefix$_userId';
  String get _customTagsKey => '$_customTagsPrefix$_userId';
  String get _lockKey => '$_lockPrefix$_userId';

  // ── Repository Delegations ───────────────────────────────────────────────

  Future<void> createEntry(JournalEntry entry) =>
      _repository.createEntry(entry);

  Future<void> updateEntry(JournalEntry entry) =>
      _repository.updateEntry(entry);

  Future<void> deleteEntry(String id) => _repository.deleteEntry(id);

  Future<JournalEntry?> getEntryById(String id) => _repository.getEntryById(id);

  Future<List<JournalEntry>> getEntries() => _repository.getEntries(_userId);

  Future<List<JournalEntry>> getEntriesForDate(DateTime date) =>
      _repository.getEntriesForDate(_userId, date);

  Future<List<JournalEntry>> getEntriesForMonth(int year, int month) =>
      _repository.getEntriesForMonth(_userId, year, month);

  Future<List<JournalEntry>> searchEntries(String query) =>
      _repository.searchEntries(_userId, query);

  Future<List<JournalEntry>> getFavoriteEntries() =>
      _repository.getFavoriteEntries(_userId);

  // ── Draft Autosave ───────────────────────────────────────────────────────

  Future<void> saveDraft(JournalDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (draft.isEmpty) {
        await prefs.remove(_draftKey);
      } else {
        await prefs.setString(_draftKey, draft.toJson());
      }
    } catch (e) {
      debugPrint('Error saving journal draft: $e');
    }
  }

  Future<JournalDraft?> getDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw == null || raw.isEmpty) return null;
      final draft = JournalDraft.fromJson(raw);
      return draft.isEmpty ? null : draft;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (e) {
      debugPrint('Error clearing journal draft: $e');
    }
  }

  // ── Tags Management ──────────────────────────────────────────────────────

  Future<List<String>> getAllTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = prefs.getStringList(_customTagsKey) ?? [];
      final combined = {...kDefaultTags, ...custom}.toList();
      return combined;
    } catch (_) {
      return kDefaultTags;
    }
  }

  Future<void> addCustomTag(String tag) async {
    final clean = tag.trim();
    if (clean.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = (prefs.getStringList(_customTagsKey) ?? []).toSet();
      custom.add(clean);
      await prefs.setStringList(_customTagsKey, custom.toList());
    } catch (e) {
      debugPrint('Error adding custom tag: $e');
    }
  }

  // ── Journal Lock ─────────────────────────────────────────────────────────

  Future<bool> isJournalLockEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_lockKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setJournalLockEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lockKey, enabled);
    } catch (e) {
      debugPrint('Error toggling journal lock: $e');
    }
  }

  Future<void> saveLockPin(String pin) async {
    if (_storageService != null) {
      await _storageService.saveLocalPin(pin);
    }
  }

  Future<bool> hasLockPin() async {
    if (_storageService != null) {
      return _storageService.hasLocalPin();
    }
    return false;
  }

  Future<bool> verifyLockPin(String candidatePin) async {
    if (_storageService != null) {
      return _storageService.verifyLocalPin(candidatePin);
    }
    return true;
  }

  // ── Export Utilities (Future-Proofing) ───────────────────────────────────

  String exportAsJson(List<JournalEntry> entries) {
    final list = entries.map((e) => e.toMap()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  String exportAsPlainText(List<JournalEntry> entries) {
    final buffer = StringBuffer();
    final fmt = DateFormat('MMMM d, yyyy • h:mm a');

    for (final e in entries) {
      buffer.writeln('========================================');
      buffer.writeln(fmt.format(e.createdAt));
      if (e.mood != null) buffer.writeln('Mood: ${e.mood!.label}');
      if (e.title != null && e.title!.isNotEmpty) {
        buffer.writeln('Title: ${e.title}');
      }
      if (e.tags.isNotEmpty) buffer.writeln('Tags: ${e.tags.join(', ')}');
      buffer.writeln('----------------------------------------');
      buffer.writeln(e.content);
      buffer.writeln('\n');
    }
    return buffer.toString();
  }
}
