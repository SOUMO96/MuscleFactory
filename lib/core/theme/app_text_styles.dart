import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Named text styles built on Manrope — bold, geometric, athletic.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.15,
        letterSpacing: -0.5,
      );

  static TextStyle get h1 => GoogleFonts.manrope(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get h2 => GoogleFonts.manrope(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get h3 => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.manrope(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.manrope(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
      );

  static TextStyle get button => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.background,
      );
}
