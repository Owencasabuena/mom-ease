import '../models/user_model.dart';

/// Abstract contract for authentication providers in MomEase.
/// This decouples the UI and business logic from the underlying auth mechanism
/// (Local, Firebase Google, or future auth methods).
abstract class AuthService {
  /// Fetches the currently authenticated or locally stored user.
  Future<UserModel?> getCurrentUser();

  /// Creates or logs into a local offline account.
  Future<UserModel> signInLocally({
    required String displayName,
    String? pin,
  });

  /// Signs in with Google via Firebase Authentication.
  Future<UserModel> signInWithGoogle();

  /// Updates the user's display name.
  Future<UserModel> updateDisplayName(String newName);

  /// Updates or sets the user's local PIN/password.
  Future<void> updateLocalPin({
    String? oldPin,
    required String newPin,
  });

  /// Signs out of the current session.
  Future<void> signOut();

  /// Deletes the local profile and credentials from this device.
  Future<void> deleteAccount();
}
