import '../../../core/services/storage_service.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// Exception thrown when local authentication operations fail.
class LocalAuthException implements Exception {
  final String message;
  const LocalAuthException(this.message);

  @override
  String toString() => message;
}

/// Offline-first local authentication service for MomEase.
/// Keeps all user profile details and credentials strictly on the device.
class LocalAuthService implements AuthService {
  final StorageService _storageService;

  LocalAuthService(this._storageService);

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _storageService.getUser();
    if (user == null) return null;

    final hasPin = await _storageService.hasLocalPin();
    return user.copyWith(hasPin: hasPin);
  }

  @override
  Future<UserModel> signInLocally({
    required String displayName,
    String? pin,
  }) async {
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      throw const LocalAuthException('Please enter a display name.');
    }

    final trimmedPin = pin?.trim();
    final bool hasPin = trimmedPin != null && trimmedPin.isNotEmpty;

    if (hasPin) {
      if (trimmedPin.length < 4) {
        throw const LocalAuthException('PIN/Password must be at least 4 characters.');
      }
      await _storageService.saveLocalPin(trimmedPin);
    }

    final newUser = UserModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      displayName: trimmedName,
      authType: AuthType.local,
      createdAt: DateTime.now(),
      hasPin: hasPin,
    );

    await _storageService.saveUser(newUser);
    return newUser;
  }

  @override
  Future<UserModel> updateDisplayName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw const LocalAuthException('Display name cannot be empty.');
    }

    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw const LocalAuthException('No local account found to update.');
    }

    final updatedUser = currentUser.copyWith(displayName: trimmed);
    await _storageService.saveUser(updatedUser);
    return updatedUser;
  }

  @override
  Future<void> updateLocalPin({
    String? oldPin,
    required String newPin,
  }) async {
    final currentHasPin = await _storageService.hasLocalPin();
    if (currentHasPin) {
      if (oldPin == null || oldPin.isEmpty) {
        throw const LocalAuthException('Please enter your current PIN.');
      }
      final isOldValid = await _storageService.verifyLocalPin(oldPin);
      if (!isOldValid) {
        throw const LocalAuthException('Current PIN is incorrect.');
      }
    }

    final trimmedNewPin = newPin.trim();
    if (trimmedNewPin.isEmpty) {
      // Removing PIN
      await _storageService.deleteLocalPin();
      final user = await getCurrentUser();
      if (user != null) {
        await _storageService.saveUser(user.copyWith(hasPin: false));
      }
      return;
    }

    if (trimmedNewPin.length < 4) {
      throw const LocalAuthException('New PIN must be at least 4 characters.');
    }

    await _storageService.saveLocalPin(trimmedNewPin);
    final user = await getCurrentUser();
    if (user != null) {
      await _storageService.saveUser(user.copyWith(hasPin: true));
    }
  }

  @override
  Future<void> signOut() async {
    // For local users, signing out clears session keys
    await _storageService.clearUser();
  }

  @override
  Future<void> deleteAccount() async {
    // Completely deletes all local profile entries and secure keys
    await _storageService.clearAll();
  }

  @override
  Future<UserModel> signInWithGoogle() {
    throw UnsupportedError(
      'signInWithGoogle must be invoked via GoogleAuthService.',
    );
  }
}
