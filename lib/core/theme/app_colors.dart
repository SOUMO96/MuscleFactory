import 'package:flutter/material.dart';

/// Color palette: warm neutrals, one red accent, no gradients.
/// Fields are mutable, not const, so the app can switch light/dark at runtime
/// without every call site going through Theme.of(context). Call
/// [AppColors.apply] on each rebuild (see AppThemeController and main.dart).
class AppColors {
  AppColors._();

  static Color background = _dark.background;
  static Color surface = _dark.surface;
  static Color surfaceVariant = _dark.surfaceVariant;
  static Color card = _dark.card;

  static Color primary = _dark.primary;
  static Color secondary = _dark.secondary;

  static Color success = _dark.success;
  static Color warning = _dark.warning;
  static Color error = _dark.error;

  static Color textPrimary = _dark.textPrimary;
  static Color textSecondary = _dark.textSecondary;
  static Color textMuted = _dark.textMuted;

  static Color divider = _dark.divider;

  /// Tinted accent background, for tags/badges ("Made for you").
  static Color accentSoft = _dark.accentSoft;
  /// Deep accent, for text-on-light-accent-background states.
  static Color accentDeep = _dark.accentDeep;

  /// A flat "gradient" (both stops equal) for widgets that still expect a
  /// gradient, such as PrimaryButton and the auth icon badges.
  static List<Color> primaryGradient = _dark.primaryGradient;
  static List<Color> heroGradient = _dark.heroGradient;

  static void apply(Brightness brightness) {
    final set = brightness == Brightness.dark ? _dark : _light;
    background = set.background;
    surface = set.surface;
    surfaceVariant = set.surfaceVariant;
    card = set.card;
    primary = set.primary;
    secondary = set.secondary;
    success = set.success;
    warning = set.warning;
    error = set.error;
    textPrimary = set.textPrimary;
    textSecondary = set.textSecondary;
    textMuted = set.textMuted;
    divider = set.divider;
    accentSoft = set.accentSoft;
    accentDeep = set.accentDeep;
    primaryGradient = set.primaryGradient;
    heroGradient = set.heroGradient;
  }
}

class _AppColorSet {
  const _AppColorSet({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.card,
    required this.primary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.accentSoft,
    required this.accentDeep,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color card;
  final Color primary;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final Color accentSoft;
  final Color accentDeep;

  List<Color> get primaryGradient => [primary, primary];
  List<Color> get heroGradient => [background, background];
}

const _lightText = Color(0xFF201E1D);
const _darkText = Color(0xFFF1EFEE);

final _light = _AppColorSet(
  background: const Color(0xFFF3F2F2),
  surface: const Color(0xFFEAE9E9),
  surfaceVariant: const Color(0xFFEAE7E7),
  card: const Color(0xFFEAE9E9),
  primary: const Color(0xFFEC3013),
  secondary: const Color(0xFFFF563C),
  success: const Color(0xFF1E8E3E),
  warning: const Color(0xFFB45309),
  error: const Color(0xFFAE1800),
  textPrimary: _lightText,
  textSecondary: _lightText.withValues(alpha: 0.62),
  textMuted: _lightText.withValues(alpha: 0.50),
  divider: _lightText.withValues(alpha: 0.40),
  accentSoft: const Color(0xFFFFF2EF),
  accentDeep: const Color(0xFF7C1405),
);

final _dark = _AppColorSet(
  background: const Color(0xFF161514),
  surface: const Color(0xFF232120),
  surfaceVariant: const Color(0xFF2A2827),
  card: const Color(0xFF232120),
  primary: const Color(0xFFF0391C),
  secondary: const Color(0xFFFF563C),
  success: const Color(0xFF3FBE6B),
  warning: const Color(0xFFE0A339),
  error: const Color(0xFFFF9783),
  textPrimary: _darkText,
  textSecondary: _darkText.withValues(alpha: 0.62),
  textMuted: _darkText.withValues(alpha: 0.50),
  divider: _darkText.withValues(alpha: 0.26),
  accentSoft: const Color(0xFF3A1A14),
  accentDeep: const Color(0xFFFFC4B8),
);
