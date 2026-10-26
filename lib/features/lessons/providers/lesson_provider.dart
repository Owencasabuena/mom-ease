import 'package:flutter/foundation.dart';

import '../models/lesson.dart';
import '../services/lesson_recommendation_service.dart';
import '../services/lesson_service.dart';

/// Presentation state provider for the Lessons catalogue.
class LessonProvider extends ChangeNotifier {
  final LessonService _lessonService;
  final LessonRecommendationService _recommendationService;

  bool _isLoading = false;
  String? _errorMessage;
  List<Lesson> _allLessons = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  String _currentLanguage = 'en';
  Set<String> _bookmarkedIds = {};
  Set<String> _completedIds = {};
  String? _lastOpenedId;
  String? _currentMoodId;
  Lesson? _recommendedLesson;

  LessonProvider(
    this._lessonService, [
    LessonRecommendationService? recommendationService,
  ]) : _recommendationService =
           recommendationService ?? LessonRecommendationService();

  // ── Getters ──────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Lesson> get allLessons => _allLessons;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get currentLanguage => _currentLanguage;
  Set<String> get bookmarkedIds => _bookmarkedIds;
  Set<String> get completedIds => _completedIds;
  Lesson? get recommendedLesson => _recommendedLesson;

  Lesson? get continueLearningLesson {
    if (_lastOpenedId == null) return null;
    try {
      final lesson = _allLessons.firstWhere((l) => l.id == _lastOpenedId);
      // If already completed, do not emphasize continue learning
      if (_completedIds.contains(lesson.id)) return null;
      return lesson;
    } catch (_) {
      return null;
    }
  }

  List<Lesson> get bookmarkedLessons =>
      _allLessons.where((l) => _bookmarkedIds.contains(l.id)).toList();

  /// Filtered lessons based on selected category and search query.
  List<Lesson> get filteredLessons {
    List<Lesson> list = List.of(_allLessons);

    // 1. Category filtering
    if (_selectedCategory == 'saved') {
      list = list.where((l) => _bookmarkedIds.contains(l.id)).toList();
    } else if (_selectedCategory != 'all') {
      final cat = _selectedCategory.toLowerCase();
      list = list.where((l) => l.category.toLowerCase() == cat).toList();
    }

    // 2. Search query filtering
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((lesson) {
        final titleEn = lesson.title['en']?.toLowerCase() ?? '';
        final titleTl = lesson.title['tl']?.toLowerCase() ?? '';
        final descEn = lesson.shortDescription['en']?.toLowerCase() ?? '';
        final descTl = lesson.shortDescription['tl']?.toLowerCase() ?? '';
        final category = lesson.category.toLowerCase();
        final tags = lesson.tags.map((t) => t.toLowerCase()).join(' ');

        return titleEn.contains(query) ||
            titleTl.contains(query) ||
            descEn.contains(query) ||
            descTl.contains(query) ||
            category.contains(query) ||
            tags.contains(query);
      }).toList();
    }

    return list;
  }

  // ── Initialization ───────────────────────────────────────────────────────

  Future<void> init({String? moodId}) async {
    _isLoading = true;
    _errorMessage = null;
    if (moodId != null) _currentMoodId = moodId;
    notifyListeners();

    try {
      final lessons = await _lessonService.getAllLessons();
      final lang = await _lessonService.getPreferredLanguage();
      final bookmarks = await _lessonService.getBookmarkedIds();
      final completed = await _lessonService.getCompletedIds();
      final lastOpened = await _lessonService.getLastOpenedLessonId();

      _allLessons = lessons;
      _currentLanguage = lang;
      _bookmarkedIds = bookmarks;
      _completedIds = completed;
      _lastOpenedId = lastOpened;

      _computeRecommendation();
    } catch (e) {
      _errorMessage = 'No lessons are available right now.';
      debugPrint('Error initializing LessonProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── User Actions ──────────────────────────────────────────────────────────

  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      notifyListeners();
      await _lessonService.savePreferredLanguage(lang);
    }
  }

  Future<void> toggleBookmark(String lessonId) async {
    final isBookmarked = await _lessonService.toggleBookmark(lessonId);
    if (isBookmarked) {
      _bookmarkedIds.add(lessonId);
    } else {
      _bookmarkedIds.remove(lessonId);
    }
    notifyListeners();
  }

  Future<void> toggleCompleted(String lessonId) async {
    final isCompleted = await _lessonService.toggleCompleted(lessonId);
    if (isCompleted) {
      _completedIds.add(lessonId);
    } else {
      _completedIds.remove(lessonId);
    }
    _computeRecommendation();
    notifyListeners();
  }

  Future<void> recordLessonOpened(String lessonId) async {
    _lastOpenedId = lessonId;
    await _lessonService.recordLessonOpened(lessonId);
    notifyListeners();
  }

  void updateCurrentMood(String? moodId) {
    if (_currentMoodId != moodId) {
      _currentMoodId = moodId;
      _computeRecommendation();
      notifyListeners();
    }
  }

  void _computeRecommendation() {
    if (_allLessons.isEmpty) {
      _recommendedLesson = null;
      return;
    }
    try {
      _recommendedLesson = _recommendationService.getRecommendation(
        allLessons: _allLessons,
        moodId: _currentMoodId,
        completedIds: _completedIds,
        lastOpenedId: _lastOpenedId,
      );
    } catch (_) {
      _recommendedLesson = null;
    }
  }
}
