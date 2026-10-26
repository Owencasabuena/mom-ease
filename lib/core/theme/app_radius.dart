import 'package:flutter/material.dart';

/// Centralized border radius tokens for MomEase soft rounded UI.
/// Small: 8px, Medium: 16px, Large: 20px, Extra Large: 24px.
abstract final class AppRadius {
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double pill = 999.0;

  static final BorderRadius small = BorderRadius.circular(sm);
  static final BorderRadius medium = BorderRadius.circular(md);
  static final BorderRadius large = BorderRadius.circular(lg);
  static final BorderRadius extraLarge = BorderRadius.circular(xl);
  static final BorderRadius roundedPill = BorderRadius.circular(pill);

  /// Standard bottom sheet top corner radius
  static const BorderRadius bottomSheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
