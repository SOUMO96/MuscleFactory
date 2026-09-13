import 'package:flutter/material.dart';

/// Central color palette for IronPulse.
///
/// Dark, high-contrast base with a neon-lime primary accent (energy,
/// progress, "go") and an orange secondary accent (intensity, calories).
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0D0D0F);
  static const Color surface = Color(0xFF141418);
  static const Color surfaceVariant = Color(0xFF1E1E24);
  static const Color card = Color(0xFF1B1B21);

  // Accents
  static const Color primary = Color(0xFFCCFF00);
  static const Color primaryDark = Color(0xFFA8D600);
  static const Color secondary = Color(0xFFFF5A1F);

  // Status
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFC42E);
  static const Color error = Color(0xFFFF4B4B);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9A9AA5);
  static const Color textMuted = Color(0xFF6B6B75);

  static const Color divider = Color(0xFF2A2A31);

  // Gradients
  static const List<Color> primaryGradient = [Color(0xFFCCFF00), Color(0xFF8FE000)];
  static const List<Color> orangeGradient = [Color(0xFFFF5A1F), Color(0xFFFF8A3D)];
  static const List<Color> heroGradient = [Color(0xFF23232B), Color(0xFF0D0D0F)];

  /// Rotating accent gradients used for workout thumbnails / badges so the
  /// library feels varied without breaking the core lime/orange identity.
  static const List<List<Color>> workoutGradients = [
    [Color(0xFFFF5A1F), Color(0xFFFF8A3D)], // orange
    [Color(0xFFCCFF00), Color(0xFF8FE000)], // lime
    [Color(0xFF2E7CF6), Color(0xFF6FB1FF)], // blue
    [Color(0xFF9B5CFF), Color(0xFFC49BFF)], // purple
    [Color(0xFFFF4D9D), Color(0xFFFF8AC1)], // pink
    [Color(0xFF00D1B2), Color(0xFF5CF0D0)], // teal
  ];
}
