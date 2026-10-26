import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../models/journal_prompt.dart';
import '../services/journal_prompt_service.dart';
import '../services/journal_service.dart';

/// Presentation state provider for the Journaling feature.
class JournalProvider extends ChangeNotifier {
  final JournalService _journalService;
  final JournalPromptService _promptService;

  bool _isLoading = false;
  String? _errorMessage;
  List<JournalEntry> _entries = [];
  JournalDraft? _savedDraft;
  List<String> _availableTags = [];
  JournalPrompt? _featuredPrompt;

  // Filter state
  String _searchQuery = '';
  bool _onlyFavorites = false;
  String? _filterMoodId;
  String? _filterTag;
  DateTime? _filterDate;

  // Lock state
  bool _isLockEnabled = false;
  bool _isUnlocked = false;

  JournalProvider(
    this._journalService, [
    JournalPromptService? promptService,
  ]) : _promptService = promptService ?? JournalPromptService();

  // ── Getters ──────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<JournalEntry> get allEntries => _entries;
  JournalDraft? get savedDraft => _savedDraft;
  List<String> get availableTags => _availableTags;
  JournalPrompt? get featuredPrompt => _featuredPrompt;

  String get searchQuery => _searchQuery;
  bool get onlyFavorites => _onlyFavorites;
  String? get filterMoodId => _filterMoodId;
  String? get filterTag => _filterTag;
  DateTime? get filterDate => _filterDate;

  bool get isLockEnabled => _isLockEnabled;
  bool get isUnlocked => _isUnlocked;
  bool get isLocked => _isLockEnabled && !_isUnlocked;

  bool get hasActiveFilters =>
      _onlyFavorites ||
      _filterMoodId != null ||
      _filterTag != null ||
      _filterDate != null ||
      _searchQuery.isNotEmpty;

  /// Filtered and searched journal entries.
  List<JournalEntry> get filteredEntries {
    var list = List.of(_entries);

    // Filter by favorites
    if (_onlyFavorites) {
      list = list.where((e) => e.isFavorite).toList();
    }

    // Filter by mood
    if (_filterMoodId != null) {
      list = list.where((e) => e.moodId == _filterMoodId).toList();
    }

    // Filter by tag
    if (_filterTag != null) {
      final tagLower = _filterTag!.toLowerCase();
      list = list
          .where((e) => e.tags.any((t) => t.toLowerCase() == tagLower))
          .toList();
    }

    // Filter by specific date
    if (_filterDate != null) {
      list = list.where((e) {
        return e.date.year == _filterDate!.year &&
            e.date.month == _filterDate!.month &&
            e.date.day == _filterDate!.day;
      }).toList();
    }

    // Search query
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((e) {
        final title = e.title?.toLowerCase() ?? '';
        final content = e.content.toLowerCase();
        final tags = e.tags.map((t) => t.toLowerCase()).join(' ');
        return title.contains(query) ||
            content.contains(query) ||
            tags.contains(query);
      }).toList();
    }

    return list;
  }

  // ── Initialization ───────────────────────────────────────────────────────

  Future<void> init({String? currentMoodId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _entries = await _journalService.getEntries();
      _savedDraft = await _journalService.getDraft();
      _availableTags = await _journalService.getAllTags();
      _isLockEnabled = await _journalService.isJournalLockEnabled();
      _featuredPrompt = _promptService.getFeaturedPrompt(currentMoodId);
    } catch (e) {
      debugPrint('Error initializing JournalProvider: $e');
      _errorMessage = 'Could not load your journal. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadEntries() async {
    try {
      _entries = await _journalService.getEntries();
      _savedDraft = await _journalService.getDraft();
      _availableTags = await _journalService.getAllTags();
      notifyListeners();
    } catch (e) {
      debugPrint('Error reloading journal entries: $e');
    }
  }

  // ── Entry Operations ──────────────────────────────────────────────────────

  Future<bool> saveEntry(JournalEntry entry) async {
    try {
      // Check if entry already exists (update vs create)
      final existingIndex = _entries.indexWhere((e) => e.id == entry.id);
      if (existingIndex >= 0) {
        await _journalService.updateEntry(entry);
        _entries[existingIndex] = entry;
      } else {
        await _journalService.createEntry(entry);
        _entries.insert(0, entry);
      }
      // Clear draft upon successful save
      await _journalService.clearDraft();
      _savedDraft = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving entry: $e');
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    try {
      await _journalService.deleteEntry(id);
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting entry: $e');
      return false;
    }
  }

  Future<void> toggleFavorite(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index < 0) return;

    final updated = _entries[index].copyWith(
      isFavorite: !_entries[index].isFavorite,
    );
    _entries[index] = updated;
    notifyListeners();

    await _journalService.updateEntry(updated);
  }

  // ── Draft Operations ──────────────────────────────────────────────────────

  Future<void> saveDraft(JournalDraft draft) async {
    _savedDraft = draft.isEmpty ? null : draft;
    notifyListeners();
    await _journalService.saveDraft(draft);
  }

  Future<void> discardDraft() async {
    _savedDraft = null;
    notifyListeners();
    await _journalService.clearDraft();
  }

  // ── Tags ─────────────────────────────────────────────────────────────────

  Future<void> addCustomTag(String tag) async {
    await _journalService.addCustomTag(tag);
    _availableTags = await _journalService.getAllTags();
    notifyListeners();
  }

  // ── Filter Controls ──────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterFavorites(bool onlyFavorites) {
    _onlyFavorites = onlyFavorites;
    notifyListeners();
  }

  void setFilterMood(String? moodId) {
    _filterMoodId = moodId;
    notifyListeners();
  }

  void setFilterTag(String? tag) {
    _filterTag = tag;
    notifyListeners();
  }

  void setFilterDate(DateTime? date) {
    _filterDate = date;
    notifyListeners();
  }

  void clearFilters() {
    _onlyFavorites = false;
    _filterMoodId = null;
    _filterTag = null;
    _filterDate = null;
    _searchQuery = '';
    notifyListeners();
  }

  // ── Journal Lock ─────────────────────────────────────────────────────────

  Future<bool> verifyAndUnlock(String pin) async {
    final valid = await _journalService.verifyLockPin(pin);
    if (valid) {
      _isUnlocked = true;
      notifyListeners();
    }
    return valid;
  }

  void lock() {
    if (_isLockEnabled) {
      _isUnlocked = false;
      notifyListeners();
    }
  }

  Future<void> saveLockPin(String pin) async {
    await _journalService.saveLockPin(pin);
    notifyListeners();
  }

  Future<bool> hasLockPin() => _journalService.hasLockPin();

  Future<void> setLockEnabled(bool enabled) async {
    _isLockEnabled = enabled;
    if (!enabled) _isUnlocked = true;
    await _journalService.setJournalLockEnabled(enabled);
    notifyListeners();
  }
}
