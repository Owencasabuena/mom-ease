import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/services/storage_service.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// Exception thrown when Firebase is required but not yet configured.
class FirebaseNotConfiguredException implements Exception {
  final String message;
  const FirebaseNotConfiguredException([
    this.message = 'Google Sign-In requires Firebase configuration.',
  ]);

  @override
  String toString() => message;
}

/// Service managing Google Authentication via Firebase Auth.
///
/// Designed with clean architecture so Firebase can be plugged in seamlessly
/// without altering local storage or offline functionality.
class GoogleAuthService implements AuthService {
  final StorageService _storageService;

  /// Track if Firebase has been initialized in this project runtime
  final bool isFirebaseReady;

  final String? serverClientId;

  GoogleAuthService(
    this._storageService, {
    this.isFirebaseReady = false,
    this.serverClientId,
  });

  /// Returns true if Firebase has been initialized and configured.
  bool get isConfigured => isFirebaseReady;

  @override
  Future<UserModel?> getCurrentUser() async {
    if (isFirebaseReady) {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        return UserModel(
          id: fbUser.uid,
          displayName: fbUser.displayName ?? 'Mama',
          email: fbUser.email,
          photoUrl: fbUser.photoURL,
          authType: AuthType.google,
          createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
        );
      }
    }

    final savedUser = _storageService.getUser();
    if (savedUser != null && savedUser.isGoogle) {
      return savedUser;
    }
    return null;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    if (!isFirebaseReady) {
      throw const FirebaseNotConfiguredException(
        'Google Sign-In requires Firebase configuration.\n'
        'Please follow the setup steps in the documentation or continue locally.',
      );
    }

    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;
      await signIn.initialize(serverClientId: serverClientId);
      final GoogleSignInAccount googleUser = await signIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to obtain user from Firebase.');
      }

      final userModel = UserModel(
        id: user.uid,
        displayName: user.displayName ?? googleUser.displayName ?? 'Mama',
        email: user.email ?? googleUser.email,
        photoUrl: user.photoURL ?? googleUser.photoUrl,
        authType: AuthType.google,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
      );
      await _storageService.saveUser(userModel);
      return userModel;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw Exception(
          'Google Sign-In Web Client ID (serverClientId) is missing.\n\n'
          'Please ensure:\n'
          '1. Google provider is enabled in Firebase Console (Authentication > Sign-in method)\n'
          '2. SHA-1 fingerprint is added under Project Settings > Your apps\n'
          '3. Re-download google-services.json into android/app/ (or provide serverClientId).',
        );
      }
      throw Exception('Google Sign-In failed: ${e.description ?? e.code.name}');
    }
  }

  @override
  Future<UserModel> updateDisplayName(String newName) async {
    final current = await getCurrentUser();
    if (current == null) {
      throw const FirebaseNotConfiguredException('No active user found.');
    }
    final updated = current.copyWith(displayName: newName.trim());
    await _storageService.saveUser(updated);
    return updated;
  }

  @override
  Future<void> updateLocalPin({String? oldPin, required String newPin}) {
    throw UnsupportedError('Google accounts do not use local device PINs.');
  }

  @override
  Future<void> signOut() async {
    if (isFirebaseReady) {
      try {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _storageService.clearUser();
  }

  @override
  Future<void> deleteAccount() async {
    if (isFirebaseReady) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        await user?.delete();
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _storageService.clearAll();
  }

  @override
  Future<UserModel> signInLocally({required String displayName, String? pin}) {
    throw UnsupportedError(
      'signInLocally must be invoked via LocalAuthService.',
    );
  }
}
