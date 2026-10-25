import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../features/auth/models/user_model.dart';

/// Centralized local storage service.
/// Uses SharedPreferences for simple non-sensitive state and
/// FlutterSecureStorage for sensitive credentials (PINs, passwords, tokens).
class StorageService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  StorageService(
    this._prefs, {
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static Future<StorageService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Theme Mode ---

  ThemeMode getThemeMode() {
    final savedMode = _prefs.getString(AppConstants.keyThemeMode);
    switch (savedMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<bool> saveThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    return _prefs.setString(AppConstants.keyThemeMode, value);
  }

  // --- Onboarding & Auth State ---

  bool isOnboardingComplete() {
    return _prefs.getBool(AppConstants.keyIsOnboarded) ?? false;
  }

  Future<bool> setIsOnboardingComplete(bool value) async {
    return _prefs.setBool(AppConstants.keyIsOnboarded, value);
  }

  String? getAuthType() {
    return _prefs.getString(AppConstants.keyAuthType);
  }

  Future<bool> setAuthType(String type) async {
    return _prefs.setString(AppConstants.keyAuthType, type);
  }

  // --- User Profile Storage ---

  UserModel? getUser() {
    final jsonStr = _prefs.getString(AppConstants.keyUserData);
    if (jsonStr == null || jsonStr.isEmpty) {
      return null;
    }
    try {
      return UserModel.fromJson(jsonStr);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveUser(UserModel user) async {
    await setAuthType(user.authType.value);
    await setIsOnboardingComplete(true);
    return _prefs.setString(AppConstants.keyUserData, user.toJson());
  }

  Future<bool> clearUser() async {
    await _prefs.remove(AppConstants.keyUserData);
    await _prefs.remove(AppConstants.keyAuthType);
    await _prefs.setBool(AppConstants.keyIsOnboarded, false);
    await deleteLocalPin();
    return true;
  }

  // --- Secure Storage for Local PIN / Password ---

  Future<void> saveLocalPin(String pin) async {
    await _secureStorage.write(
      key: AppConstants.keySecurePin,
      value: pin,
    );
  }

  Future<String?> getLocalPin() async {
    return _secureStorage.read(key: AppConstants.keySecurePin);
  }

  Future<bool> hasLocalPin() async {
    final pin = await getLocalPin();
    return pin != null && pin.isNotEmpty;
  }

  Future<bool> verifyLocalPin(String candidatePin) async {
    final stored = await getLocalPin();
    if (stored == null) return true;
    return stored == candidatePin;
  }

  Future<void> deleteLocalPin() async {
    await _secureStorage.delete(key: AppConstants.keySecurePin);
  }

  // --- Clear Everything (Account Deletion) ---

  Future<void> clearAll() async {
    final currentTheme = _prefs.getString(AppConstants.keyThemeMode);
    await _prefs.clear();
    if (currentTheme != null) {
      await _prefs.setString(AppConstants.keyThemeMode, currentTheme);
    }
    await _secureStorage.deleteAll();
  }
}
