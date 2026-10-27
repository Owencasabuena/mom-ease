import 'package:flutter/material.dart';

/// Centralized references to MomEase finalized branding assets.
abstract final class AppAssets {
  static const String appIcon = 'assets/branding/app_icon.jpg';
  static const String stackedLogoLight =
      'assets/branding/stacked_logo_light.png';
  static const String stackedLogoDark = 'assets/branding/stacked_logo_dark.png';
  static const String horizontalLogoLight =
      'assets/branding/horizontal_logo_light.png';
  static const String horizontalLogoDark =
      'assets/branding/horizontal_logo_dark.png';

  /// Resolves the appropriate stacked logo variant for the active brightness.
  static String stackedLogo(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? stackedLogoDark
        : stackedLogoLight;
  }

  /// Resolves the appropriate horizontal logo variant for the active brightness.
  static String horizontalLogo(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? horizontalLogoDark
        : horizontalLogoLight;
  }
}
