import 'package:flutter/foundation.dart';

import '../models/mood_entry.dart';
import '../models/mood_type.dart';
import '../services/mood_service.dart';

class MoodProvider extends ChangeNotifier {
  MoodProvider(this._service, this._userId) {
    _selectedDate = _today;
    _displayedYear = _today.year;
    _displayedMonth = _today.month;
  }

  final MoodService _service;
  final String _userId;
  String get userId => _userId;

  // ── State ────────────────────────────────────────────────────────────────────

  late DateTime _selectedDate;
  late int _displayedYear;
  late int _displayedMonth;

  MoodEntry? _selectedEntry;
  List<MoodEntry> _monthEntries = [];
  Map<MoodType, int> _monthlyCounts = {};
  bool _loading = false;
  String? _error;
  bool _showSupportMessage = false;

  // ── Getters ──────────────────────────────────────────────────────────────────

  DateTime get selectedDate => _selectedDate;
  int get displayedYear => _displayedYear;
  int get displayedMonth => _displayedMonth;
  MoodEntry? get selectedEntry => _selectedEntry;
  List<MoodEntry> get monthEntries => _monthEntries;
  Map<MoodType, int> get monthlyCounts => _monthlyCounts;
  bool get loading => _loading;
  String? get error => _error;
  bool get showSupportMessage => _showSupportMessage;

  bool get isFutureDate => _selectedDate.isAfter(_today);
  int get totalCheckInsThisMonth => _monthEntries.length;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // ── Initialise ───────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadMonth();
    await _loadSelectedEntry();
    await _checkSupportThreshold();
  }

  // ── Date navigation ──────────────────────────────────────────────────────────

  Future<void> selectDate(DateTime date) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    // If selected date is in a different month, update displayed month
    if (date.year != _displayedYear || date.month != _displayedMonth) {
      _displayedYear = date.year;
      _displayedMonth = date.month;
      await _loadMonth();
    }
    await _loadSelectedEntry();
    notifyListeners();
  }

  Future<void> goToPreviousMonth() async {
    if (_displayedMonth == 1) {
      _displayedMonth = 12;
      _displayedYear--;
    } else {
      _displayedMonth--;
    }
    await _loadMonth();
    notifyListeners();
  }

  Future<void> goToNextMonth() async {
    if (_displayedMonth == 12) {
      _displayedMonth = 1;
      _displayedYear++;
    } else {
      _displayedMonth++;
    }
    await _loadMonth();
    notifyListeners();
  }

  // ── Mood persistence ─────────────────────────────────────────────────────────

  Future<String?> saveMoodForSelectedDate(MoodType mood, {String? note}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final entry = MoodEntry(
        id: _selectedDate.millisecondsSinceEpoch,
        userId: _userId,
        date: _selectedDate,
        moodValue: mood.value,
        note: note,
        createdAt: now,
        updatedAt: now,
      );

      final exists = await _service.hasMoodForDate(_userId, _selectedDate);
      if (exists) {
        await _service.updateMood(entry);
      } else {
        await _service.saveMood(entry);
      }

      await _loadMonth();
      await _loadSelectedEntry();
      await _checkSupportThreshold();
      return null; // success
    } catch (e) {
      _error = 'Could not save your mood. Please try again.';
      return _error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  Future<void> _loadMonth() async {
    try {
      _monthEntries = await _service.getMoodsForMonth(
        _userId,
        _displayedYear,
        _displayedMonth,
      );
      _monthlyCounts = await _service.getMoodCountsForMonth(
        _userId,
        _displayedYear,
        _displayedMonth,
      );
    } catch (_) {
      _error = 'Something went wrong while loading your mood history.';
    }
  }

  Future<void> _loadSelectedEntry() async {
    try {
      _selectedEntry = await _service.getMoodForDate(_userId, _selectedDate);
    } catch (_) {
      _selectedEntry = null;
    }
  }

  Future<void> _checkSupportThreshold() async {
    _showSupportMessage = await _service.shouldShowSupportMessage(_userId);
  }

  /// Lookup a logged mood for any arbitrary day (used by calendar / date selector).
  MoodEntry? entryForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    try {
      return _monthEntries.firstWhere(
        (e) =>
            e.date.year == d.year &&
            e.date.month == d.month &&
            e.date.day == d.day,
      );
    } catch (_) {
      return null;
    }
  }
}
