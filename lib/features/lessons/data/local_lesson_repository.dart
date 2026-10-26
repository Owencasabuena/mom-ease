import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/lesson.dart';
import 'lesson_repository.dart';

/// Local offline implementation of [LessonRepository] that loads lessons
/// directly from [assetPath] (`assets/data/lessons.json`).
class LocalLessonRepository implements LessonRepository {
  final String assetPath;
  List<Lesson>? _cachedLessons;

  LocalLessonRepository({this.assetPath = 'assets/data/lessons.json'});

  @override
  Future<List<Lesson>> getAllLessons() async {
    if (_cachedLessons != null) {
      return _cachedLessons!;
    }

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is List) {
        _cachedLessons = decoded
            .map((e) => Lesson.fromMap(e as Map<String, dynamic>))
            .toList();
        return _cachedLessons!;
      } else {
        debugPrint('Warning: Expected a JSON array in $assetPath');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading lessons from $assetPath: $e\n$stackTrace');
      return [];
    }
  }

  @override
  Future<Lesson?> getLessonById(String id) async {
    final lessons = await getAllLessons();
    try {
      return lessons.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Lesson>> getLessonsByCategory(String category) async {
    final lessons = await getAllLessons();
    if (category.toLowerCase() == 'all') return lessons;
    return lessons
        .where((l) => l.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  @override
  Future<List<Lesson>> getLessonsByMood(String moodTag) async {
    final lessons = await getAllLessons();
    final tagLower = moodTag.toLowerCase();
    return lessons
        .where((l) => l.moodTags.any((t) => t.toLowerCase() == tagLower))
        .toList();
  }

  @override
  Future<List<Lesson>> searchLessons(String query, {String lang = 'en'}) async {
    final lessons = await getAllLessons();
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return lessons;

    return lessons.where((lesson) {
      final titleEn = lesson.title['en']?.toLowerCase() ?? '';
      final titleTl = lesson.title['tl']?.toLowerCase() ?? '';
      final descEn = lesson.shortDescription['en']?.toLowerCase() ?? '';
      final descTl = lesson.shortDescription['tl']?.toLowerCase() ?? '';
      final cat = lesson.category.toLowerCase();
      final tags = lesson.tags.map((t) => t.toLowerCase()).join(' ');

      return titleEn.contains(trimmed) ||
          titleTl.contains(trimmed) ||
          descEn.contains(trimmed) ||
          descTl.contains(trimmed) ||
          cat.contains(trimmed) ||
          tags.contains(trimmed);
    }).toList();
  }

  /// Invalidate in-memory cache to force re-reading the JSON bundle if updated.
  void clearCache() {
    _cachedLessons = null;
  }
}
