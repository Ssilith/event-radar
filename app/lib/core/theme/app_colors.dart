import 'package:flutter/material.dart';

// Semantic color tokens for the dark theme. Use these instead of raw hex
// literals so palette tweaks are a single-file change.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF00E5B4);

  // Surfaces (lowest -> highest elevation)
  static const Color bg = Color(0xFF0A0A0A);
  static const Color surfaceLow = Color(0xFF0E0E0E);
  static const Color surface = Color(0xFF111111);
  static const Color surfaceHigh = Color(0xFF161616);
  static const Color surfaceMuted = Color(0xFF1A1A1A);
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color surfacePill = Color(0xFF222222);

  // Lines & borders
  static const Color border = Color(0xFF181818);
  static const Color borderStrong = Color(0xFF2E2E2E);

  // Text (lightest -> darkest)
  static const Color textPrimary = Colors.white;
  static const Color textBody = Color(0xFFCCCCCC);
  static const Color textBodyAlt = Color(0xFFBFBFBF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF999999);
  static const Color textPlaceholder = Color(0xFF888888);
  static const Color textHint = Color(0xFF666666);
  static const Color textDisabled = Color(0xFF555555);
  static const Color textFaint = Color(0xFF444444);
  static const Color textFainter = Color(0xFF3A3A3A);
}
