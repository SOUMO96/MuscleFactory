import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Named text styles built on Archivo (the "Modernist" system's typeface) --
/// sharp, heavy, all-business.
///
/// Sizes intentionally match the app's *previous* type scale rather than
/// the design mock's larger headings (h1 42 / h2 32 / h3 25 in
/// styles.css): repointing these names to those sizes now would blow out
/// every existing screen's layout before Phase 3 reworks each screen to
/// the new scale. New Modernist-scale styles land alongside these as
/// screens are rebuilt, rather than mutating these out from under them.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.archivo(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.15,
        letterSpacing: -0.5,
      );

  static TextStyle get h1 => GoogleFonts.archivo(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get h2 => GoogleFonts.archivo(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  static TextStyle get h3 => GoogleFonts.archivo(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.archivo(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.archivo(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.archivo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.archivo(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.6,
      );

  static TextStyle get button => GoogleFonts.archivo(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.background,
      );
}
