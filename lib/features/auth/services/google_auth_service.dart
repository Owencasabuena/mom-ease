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

  GoogleAuthService(
    this._storageService, {
    this.isFirebaseReady = false,
  });

  /// Returns true if Firebase has been initialized and configured.
  bool get isConfigured => isFirebaseReady;

  @override
  Future<UserModel?> getCurrentUser() async {
    // ------------------------------------------------------------------------
    // TODO: [Firebase Setup Step 1]
    // When Firebase is configured, check FirebaseAuth.instance.currentUser:
    //
    // final fbUser = FirebaseAuth.instance.currentUser;
    // if (fbUser != null) {
    //   return UserModel(
    //     id: fbUser.uid,
    //     displayName: fbUser.displayName ?? 'Mama',
    //     email: fbUser.email,
    //     photoUrl: fbUser.photoURL,
    //     authType: AuthType.google,
    //     createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
    //   );
    // }
    // ------------------------------------------------------------------------

    final savedUser = _storageService.getUser();
    if (savedUser != null && savedUser.isGoogle) {
      return savedUser;
    }
    return null;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    // Check if Firebase is configured
    if (!isFirebaseReady) {
      // Graceful fallback with clear development message
      // Do NOT invent fake credentials or break the app
      throw const FirebaseNotConfiguredException(
        'Google Sign-In requires Firebase configuration.\n'
        'Please follow the setup steps in the documentation or continue locally.',
      );
    }

    // ------------------------------------------------------------------------
    // TODO: [Firebase Setup Step 2]
    // When Firebase and Google Sign-In packages are installed:
    // 1. Add packages: `flutter pub add firebase_core firebase_auth google_sign_in`
    // 2. Add Android google-services.json & iOS GoogleService-Info.plist
    // 3. Uncomment the implementation below:
    //
    // final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    // if (googleUser == null) {
    //   throw Exception('Google sign-in was cancelled by user.');
    // }
    // final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    // final AuthCredential credential = GoogleAuthProvider.credential(
    //   accessToken: googleAuth.accessToken,
    //   idToken: googleAuth.idToken,
    // );
    // final UserCredential userCredential =
    //     await FirebaseAuth.instance.signInWithCredential(credential);
    // final User? user = userCredential.user;
    // if (user == null) throw Exception('Failed to obtain user from Firebase.');
    //
    // final userModel = UserModel(
    //   id: user.uid,
    //   displayName: user.displayName ?? 'Mama',
    //   email: user.email,
    //   photoUrl: user.photoURL,
    //   authType: AuthType.google,
    //   createdAt: user.metadata.creationTime ?? DateTime.now(),
    // );
    // await _storageService.saveUser(userModel);
    // return userModel;
    // ------------------------------------------------------------------------

    throw const FirebaseNotConfiguredException();
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
    // ------------------------------------------------------------------------
    // TODO: [Firebase Setup Step 3]
    // await FirebaseAuth.instance.signOut();
    // await GoogleSignIn().signOut();
    // ------------------------------------------------------------------------
    await _storageService.clearUser();
  }

  @override
  Future<void> deleteAccount() async {
    // ------------------------------------------------------------------------
    // TODO: [Firebase Setup Step 4]
    // final user = FirebaseAuth.instance.currentUser;
    // await user?.delete();
    // ------------------------------------------------------------------------
    await _storageService.clearAll();
  }

  @override
  Future<UserModel> signInLocally({required String displayName, String? pin}) {
    throw UnsupportedError(
      'signInLocally must be invoked via LocalAuthService.',
    );
  }
}
