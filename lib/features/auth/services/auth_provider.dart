import 'package:flutter/foundation.dart';

import '../../../core/services/storage_service.dart';
import '../models/user_model.dart';
import 'google_auth_service.dart';
import 'local_auth_service.dart';

enum AuthState { initial, authenticated, unauthenticated }

/// Central state manager for authentication across MomEase.
class AuthProvider extends ChangeNotifier {
  final StorageService _storageService;
  late final LocalAuthService _localAuthService;
  late final GoogleAuthService _googleAuthService;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  AuthProvider(
    this._storageService, {
    bool isFirebaseReady = false,
    String? serverClientId,
  }) {
    _localAuthService = LocalAuthService(_storageService);
    _googleAuthService = GoogleAuthService(
      _storageService,
      isFirebaseReady: isFirebaseReady,
      serverClientId: serverClientId,
    );
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  AuthState get state {
    if (!_isInitialized) return AuthState.initial;
    return _currentUser != null
        ? AuthState.authenticated
        : AuthState.unauthenticated;
  }

  /// Initializes auth state on application launch without flashing screens.
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      final savedUser = _storageService.getUser();
      if (savedUser != null) {
        if (savedUser.isLocal) {
          _currentUser = await _localAuthService.getCurrentUser();
        } else {
          _currentUser = await _googleAuthService.getCurrentUser();
        }
      } else {
        _currentUser = null;
      }
    } catch (e) {
      _errorMessage = 'Failed to load local account data: $e';
      _currentUser = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Sets up and enters a local offline MomEase profile.
  Future<bool> continueLocally({
    required String displayName,
    String? pin,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _localAuthService.signInLocally(
        displayName: displayName,
        pin: pin,
      );
      _currentUser = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Attempts Google Sign-In via Firebase Auth.
  Future<bool> continueWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _googleAuthService.signInWithGoogle();
      _currentUser = user;
      _setLoading(false);
      return true;
    } on FirebaseNotConfiguredException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Google Sign-In failed: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Updates the user's display name and immediately syncs the profile.
  Future<bool> updateDisplayName(String newName) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      final updated = _currentUser!.isLocal
          ? await _localAuthService.updateDisplayName(newName)
          : await _googleAuthService.updateDisplayName(newName);

      _currentUser = updated;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Updates or removes the local PIN/password.
  Future<bool> updatePin({String? oldPin, required String newPin}) async {
    if (_currentUser == null || !_currentUser!.isLocal) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _localAuthService.updateLocalPin(oldPin: oldPin, newPin: newPin);
      // Refresh user object to sync hasPin status
      _currentUser = await _localAuthService.getCurrentUser();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Signs out of the current account and returns to onboarding.
  Future<void> signOut() async {
    _setLoading(true);
    try {
      if (_currentUser?.isLocal == true) {
        await _localAuthService.signOut();
      } else {
        await _googleAuthService.signOut();
      }
    } finally {
      _currentUser = null;
      _setLoading(false);
    }
  }

  /// Deletes the local profile and all stored settings.
  Future<void> deleteAccount() async {
    _setLoading(true);
    try {
      if (_currentUser?.isLocal == true) {
        await _localAuthService.deleteAccount();
      } else {
        await _googleAuthService.deleteAccount();
      }
    } finally {
      _currentUser = null;
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
