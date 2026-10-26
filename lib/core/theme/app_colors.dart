import 'package:flutter/material.dart';

/// MomEase Finalized Brand Color System & Semantic Tokens.
/// Follows the brand board specifications:
/// - Primary: Blush Rose (#E5A193)
/// - Secondary: Muted Sage (#98A890)
/// - Accent: Warm Peach (#F2C2B2)
/// - Background: Warm Cream (#FAF6F0)
/// - Surface / Card: White (#FFFFFF)
/// - Primary Text: Dark Navy Charcoal (#2C3A47)
/// - Secondary Text: Slate Gray (#576574)
/// - Border / Outline: Soft Warm Gray (#EAE4DC)
abstract final class AppColors {
  // Brand Core Colors
  static const Color primary = Color(0xFFE5A193); // Blush Rose
  static const Color secondary = Color(0xFF98A890); // Muted Sage
  static const Color accent = Color(0xFFF2C2B2); // Warm Peach

  // Tonal & Container Variants
  static const Color primaryLight = Color(0xFFFBF1EE);
  static const Color primaryContainer = Color(0xFFF7D5CE);
  static const Color primaryDark = Color(0xFFC77969);

  static const Color secondaryLight = Color(0xFFEDF2EC);
  static const Color secondaryContainer = Color(0xFFD4DDD0);
  static const Color secondaryDark = Color(0xFF6F7E67);

  static const Color accentLight = Color(0xFFFCF2EE);

  // Light Theme Surfaces & Neutrals
  static const Color background = Color(0xFFFAF6F0); // Warm Cream
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFF4ECE4); // Warm Sand
  static const Color textPrimary = Color(0xFF2C3A47); // Dark Navy Charcoal
  static const Color textSecondary = Color(0xFF576574); // Slate Gray
  static const Color border = Color(0xFFEAE4DC); // Soft Warm Gray

  // Dark Theme Surfaces & Neutrals (Navy-charcoal direction)
  static const Color darkBackground = Color(0xFF141820); // Dark Navy Charcoal
  static const Color darkSurface = Color(0xFF202630); // Slightly lighter navy
  static const Color darkSurfaceVariant = Color(0xFF28303C); // Elevated surface
  static const Color darkTextPrimary = Color(0xFFF4EFEA); // Warm Off-White
  static const Color darkTextSecondary = Color(0xFF9BA5B1); // Muted warm gray
  static const Color darkBorder = Color(0xFF333D4B); // Subtle slate gray

  // Semantic Feedback Colors (Distinct & accessible)
  static const Color success = Color(0xFF5D9B75); // Muted green
  static const Color warning = Color(0xFFD98A32); // Soft ochre
  static const Color error = Color(0xFFCC5A5A); // Gentle rose/red
  static const Color info = Color(0xFF5B88A8); // Soft blue
  static const Color favoriteStar = Color(
    0xFFE8B84B,
  ); // Harmonized golden amber

  // Distinguishable Mood Colors (Preserving semantic recognition)
  static const Color moodVeryHappy = Color(0xFFE8B84B); // Warm Golden Sunshine
  static const Color moodHappy = Color(0xFF7CAE7A); // Gentle Sage Green
  static const Color moodNeutral = Color(0xFF6B94B2); // Calm Soft Blue
  static const Color moodSad = Color(0xFFD48277); // Gentle Rose/Coral
  static const Color moodVerySad = Color(0xFF9A5252); // Muted Wine/Deep Rose

  // Backwards compatibility aliases
  static const Color dustyRose = primary;
  static const Color dustyRoseLight = primaryContainer;
  static const Color dustyRoseDark = primaryDark;
  static const Color calmingSage = secondary;
  static const Color calmingSageLight = secondaryContainer;
  static const Color calmingSageDark = secondaryDark;
  static const Color warmPeach = accent;
  static const Color softCream = background;
  static const Color warmSand = surfaceVariant;
  static const Color lightBg = background;
  static const Color lightSurface = surface;
  static const Color lightSurfaceVariant = surfaceVariant;
  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
  static const Color lightBorder = border;
  static const Color darkBg = darkBackground;
}
