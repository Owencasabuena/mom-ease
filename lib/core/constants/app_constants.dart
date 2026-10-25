/// Application-wide constants for keys, defaults, and assets.
class AppConstants {
  // App Information
  static const String appName = 'MomEase';
  static const String appTagline =
      'Support for every step of your postpartum journey.';

  // Storage Keys for SharedPreferences
  static const String keyThemeMode = 'momease_theme_mode';
  static const String keyIsOnboarded = 'momease_is_onboarded';
  static const String keyAuthType = 'momease_auth_type';
  static const String keyUserData = 'momease_user_data';

  // Secure Storage Keys for FlutterSecureStorage
  static const String keySecurePin = 'momease_secure_pin';
  static const String keySecureToken = 'momease_secure_token';

  // Privacy notice
  static const String localPrivacyNotice =
      'Using MomEase locally keeps your personal entries on this device.';
}
