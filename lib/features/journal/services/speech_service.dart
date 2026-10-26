import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum SpeechStatus {
  idle,
  listening,
  processing,
  permissionDenied,
  unavailable,
}

/// Service managing device speech recognition for hands-free postpartum journaling.
class SpeechService extends ChangeNotifier {
  final SpeechToText _speech;

  bool _isInitialized = false;
  SpeechStatus _status = SpeechStatus.idle;
  String _recognizedWords = '';
  String? _errorMessage;
  List<LocaleName> _locales = [];
  String? _selectedLocaleId;

  SpeechService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  // ── Getters ──────────────────────────────────────────────────────────────

  bool get isAvailable => _isInitialized && _speech.isAvailable;
  bool get isListening => _speech.isListening;
  SpeechStatus get status => _status;
  String get recognizedWords => _recognizedWords;
  String? get errorMessage => _errorMessage;
  List<LocaleName> get locales => _locales;
  String? get selectedLocaleId => _selectedLocaleId;

  String get statusMessage {
    switch (_status) {
      case SpeechStatus.idle:
        return 'Tap to speak';
      case SpeechStatus.listening:
        return 'Listening...';
      case SpeechStatus.processing:
        return 'Finishing transcription...';
      case SpeechStatus.permissionDenied:
        return 'Microphone access is needed for voice journaling.';
      case SpeechStatus.unavailable:
        return 'Voice input is unavailable right now. You can continue typing.';
    }
  }

  // ── Initialization ───────────────────────────────────────────────────────

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final available = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: false,
      );

      _isInitialized = available;
      if (available) {
        _status = SpeechStatus.idle;
        _locales = await _speech.locales();
        _detectBestLocale();
      } else {
        _status = SpeechStatus.unavailable;
      }
      notifyListeners();
      return available;
    } catch (e) {
      debugPrint('SpeechService initialize error: $e');
      _status = SpeechStatus.unavailable;
      _errorMessage =
          'Voice input is unavailable right now. You can continue typing.';
      notifyListeners();
      return false;
    }
  }

  void _detectBestLocale() {
    if (_locales.isEmpty) return;
    // Prefer English or Filipino if present
    final fil = _locales.where((l) =>
        l.localeId.toLowerCase().contains('fil') ||
        l.localeId.toLowerCase().contains('tl'));
    if (fil.isNotEmpty) {
      _selectedLocaleId = fil.first.localeId;
      return;
    }
    final en = _locales.where((l) => l.localeId.toLowerCase().startsWith('en'));
    if (en.isNotEmpty) {
      _selectedLocaleId = en.first.localeId;
      return;
    }
    _selectedLocaleId = _locales.first.localeId;
  }

  Future<bool> requestPermission() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.hasPermission;
  }

  List<LocaleName> getAvailableLocales() => _locales;

  void setLocale(String localeId) {
    _selectedLocaleId = localeId;
    notifyListeners();
  }

  // ── Speech Session Control ────────────────────────────────────────────────

  Future<void> startListening({
    required void Function(String text) onResult,
    String? languageCode,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    if (_speech.isListening) {
      await stopListening();
      return;
    }

    _recognizedWords = '';
    _errorMessage = null;
    _status = SpeechStatus.listening;
    notifyListeners();

    // Determine target locale
    String? targetLocale = _selectedLocaleId;
    if (languageCode != null) {
      final match = _locales.where((l) =>
          l.localeId.toLowerCase().startsWith(languageCode.toLowerCase()));
      if (match.isNotEmpty) targetLocale = match.first.localeId;
    }

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _recognizedWords = result.recognizedWords;
          onResult(result.recognizedWords);
          if (result.finalResult) {
            _status = SpeechStatus.processing;
            notifyListeners();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (_status == SpeechStatus.processing) {
                _status = SpeechStatus.idle;
                notifyListeners();
              }
            });
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: targetLocale,
          cancelOnError: true,
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('Speech listen failed: $e');
      _status = SpeechStatus.unavailable;
      _errorMessage = 'Could not start voice input.';
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    _status = SpeechStatus.processing;
    notifyListeners();
    await _speech.stop();
    await Future.delayed(const Duration(milliseconds: 300));
    _status = SpeechStatus.idle;
    notifyListeners();
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
    _status = SpeechStatus.idle;
    _recognizedWords = '';
    notifyListeners();
  }

  // ── Platform Listeners ───────────────────────────────────────────────────

  void _onError(SpeechRecognitionError errorNotification) {
    debugPrint('SpeechRecognition error: ${errorNotification.errorMsg}');
    if (errorNotification.errorMsg.toLowerCase().contains('permission') ||
        errorNotification.permanent) {
      _status = SpeechStatus.permissionDenied;
      _errorMessage = 'Microphone access is needed for voice journaling.';
    } else {
      _status = SpeechStatus.idle;
    }
    notifyListeners();
  }

  void _onStatus(String statusText) {
    if (statusText == 'listening') {
      _status = SpeechStatus.listening;
    } else if (statusText == 'notListening' || statusText == 'done') {
      if (_status == SpeechStatus.listening) {
        _status = SpeechStatus.idle;
      }
    }
    notifyListeners();
  }
}
