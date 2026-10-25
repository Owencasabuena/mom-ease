import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/lesson_repository.dart';
import '../models/lesson.dart';
import '../models/lesson_progress.dart';

/// Business service coordinating lesson content retrieval and user progress persistence.
class LessonService {
  final LessonRepository _repository;
  final String _userId;

  static const String _keyLangPref = 'lesson_pref_lang';
  static const String _keyBookmarksPrefix = 'lesson_bookmarks_';
  static const String _keyCompletedPrefix = 'lesson_completed_';
  static const String _keyLastOpenedPrefix = 'lesson_last_opened_';
  static const String _keyProgressPrefix = 'lesson_progress_map_';

  LessonService(
    this._repository, [
    this._userId = 'local_user',
  ]);

  String get _bookmarkKey => '$_keyBookmarksPrefix$_userId';
  String get _completedKey => '$_keyCompletedPrefix$_userId';
  String get _lastOpenedKey => '$_keyLastOpenedPrefix$_userId';
  String get _progressKey => '$_keyProgressPrefix$_userId';

  // ── Repository Delegations ───────────────────────────────────────────────

  Future<List<Lesson>> getAllLessons() => _repository.getAllLessons();

  Future<Lesson?> getLessonById(String id) => _repository.getLessonById(id);

  Future<List<Lesson>> getLessonsByCategory(String category) =>
      _repository.getLessonsByCategory(category);

  Future<List<Lesson>> searchLessons(String query, {String lang = 'en'}) =>
      _repository.searchLessons(query, lang: lang);

  Future<List<Lesson>> getLessonsByMood(String moodTag) =>
      _repository.getLessonsByMood(moodTag);

  // ── Language Preference ──────────────────────────────────────────────────

  Future<String> getPreferredLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLangPref) ?? 'en';
    } catch (_) {
      return 'en';
    }
  }

  Future<void> savePreferredLanguage(String lang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLangPref, lang);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  // ── Bookmarks ────────────────────────────────────────────────────────────

  Future<Set<String>> getBookmarkedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_bookmarkKey) ?? [];
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<bool> toggleBookmark(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = (prefs.getStringList(_bookmarkKey) ?? []).toSet();
      bool nowBookmarked;
      if (current.contains(lessonId)) {
        current.remove(lessonId);
        nowBookmarked = false;
      } else {
        current.add(lessonId);
        nowBookmarked = true;
      }
      await prefs.setStringList(_bookmarkKey, current.toList());
      return nowBookmarked;
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      return false;
    }
  }

  // ── Completion ───────────────────────────────────────────────────────────

  Future<Set<String>> getCompletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_completedKey) ?? [];
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<bool> toggleCompleted(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = (prefs.getStringList(_completedKey) ?? []).toSet();
      bool isNowCompleted;
      if (current.contains(lessonId)) {
        current.remove(lessonId);
        isNowCompleted = false;
      } else {
        current.add(lessonId);
        isNowCompleted = true;
      }
      await prefs.setStringList(_completedKey, current.toList());
      return isNowCompleted;
    } catch (e) {
      debugPrint('Error marking lesson complete: $e');
      return false;
    }
  }

  // ── Last Opened & Progress ────────────────────────────────────────────────

  Future<String?> getLastOpenedLessonId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastOpenedKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> recordLessonOpened(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastOpenedKey, lessonId);

      // Also persist timestamp in progress map
      final mapRaw = prefs.getString(_progressKey);
      Map<String, dynamic> progressMap = {};
      if (mapRaw != null && mapRaw.isNotEmpty) {
        try {
          progressMap = jsonDecode(mapRaw) as Map<String, dynamic>;
        } catch (_) {}
      }

      final existing = progressMap[lessonId] != null
          ? LessonProgress.fromMap(progressMap[lessonId] as Map<String, dynamic>)
          : LessonProgress(lessonId: lessonId);

      final updated = existing.copyWith(lastOpenedAt: DateTime.now());
      progressMap[lessonId] = updated.toMap();
      await prefs.setString(_progressKey, jsonEncode(progressMap));
    } catch (e) {
      debugPrint('Error recording lesson opened: $e');
    }
  }
}
