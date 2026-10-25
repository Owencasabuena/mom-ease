import 'package:flutter/material.dart';
import '../../../core/services/storage_service.dart';

/// Manages application theme mode (Light, Dark, System Default)
/// and persists user preferences across app restarts.
class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;
  late ThemeMode _themeMode;

  ThemeProvider(this._storageService) {
    _themeMode = _storageService.getThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }

  bool isUsingSystem(BuildContext context) {
    return _themeMode == ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();
    await _storageService.saveThemeMode(mode);
  }
}
