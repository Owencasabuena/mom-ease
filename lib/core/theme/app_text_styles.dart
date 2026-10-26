import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized typography hierarchy for MomEase.
/// Uses Comfortaa for display/brand-focused headings,
/// and Inter for body/UI readability.
abstract final class AppTextStyles {
  // Brand font: Comfortaa for Display & Headings
  static TextStyle display({Color color = AppColors.textPrimary}) =>
      GoogleFonts.comfortaa(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle heading1({Color color = AppColors.textPrimary}) =>
      GoogleFonts.comfortaa(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
        color: color,
        letterSpacing: -0.3,
      );

  static TextStyle heading2({Color color = AppColors.textPrimary}) =>
      GoogleFonts.comfortaa(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: color,
        letterSpacing: -0.2,
      );

  static TextStyle titleMedium({Color color = AppColors.textPrimary}) =>
      GoogleFonts.comfortaa(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  static TextStyle titleSmall({Color color = AppColors.textPrimary}) =>
      GoogleFonts.comfortaa(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  // Body & UI font: Inter
  static TextStyle bodyLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle body({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        color: color,
      );

  static TextStyle bodyMedium({Color color = AppColors.textPrimary}) =>
      body(color: color);

  static TextStyle bodySmall({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color,
      );

  static TextStyle caption({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: color,
      );

  static TextStyle button({Color? color}) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: color,
    letterSpacing: 0.1,
  );

  /// Generates a complete Material 3 TextTheme adapted to the provided text colors.
  static TextTheme createTextTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: display(color: primaryText),
      displayMedium: display(color: primaryText).copyWith(fontSize: 28),
      displaySmall: heading1(color: primaryText),
      headlineLarge: heading1(color: primaryText),
      headlineMedium: heading2(color: primaryText),
      headlineSmall: titleMedium(color: primaryText).copyWith(fontSize: 18),
      titleLarge: heading2(color: primaryText),
      titleMedium: titleMedium(color: primaryText),
      titleSmall: titleSmall(color: primaryText),
      bodyLarge: bodyLarge(color: primaryText),
      bodyMedium: body(color: primaryText),
      bodySmall: bodySmall(color: secondaryText),
      labelLarge: button(color: primaryText),
      labelMedium: caption(color: secondaryText),
      labelSmall: caption(color: secondaryText).copyWith(fontSize: 11),
    );
  }
}
