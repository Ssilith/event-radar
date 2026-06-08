import 'package:event_radar/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//* Typography tokens: Syne for headings, system for body
class AppText {
  AppText._();

  //* Display / heading styles (Syne)
  static TextStyle displayLarge() => GoogleFonts.syne(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  static TextStyle displayMedium() => GoogleFonts.syne(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle headingLarge() => GoogleFonts.syne(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle headingMedium() => GoogleFonts.syne(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle headingSmall() => GoogleFonts.syne(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle headingTiny() => GoogleFonts.syne(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  //* Body styles (non-const getters so theme-aware AppColors resolve)
  static TextStyle get bodyLarge => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get bodyMedium =>
      TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.3);

  static TextStyle get bodyMediumBold => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get bodyMutedSmall =>
      TextStyle(fontSize: 12, color: AppColors.textHint);

  static TextStyle get caption =>
      TextStyle(fontSize: 11, color: AppColors.textPlaceholder);

  static const TextStyle micro = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
  );

  //* Tiny ALL-CAPS badge above headings
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    letterSpacing: 2,
    fontWeight: FontWeight.w700,
  );

  //* InfoRow field label on the event details screen
  static TextStyle get fieldLabel => TextStyle(
    fontSize: 10,
    letterSpacing: 1.4,
    color: AppColors.textHint,
    fontWeight: FontWeight.w700,
  );
}
