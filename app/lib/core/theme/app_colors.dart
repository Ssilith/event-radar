import 'package:flutter/material.dart';

// Semantic color tokens. The same token name (e.g. AppColors.bg) returns a
// different Color depending on AppColors.brightness — set during MyApp.build
// so all descendants pick up the right shade after a theme switch.
//
// All fields except `primary` are non-const getters, which means any
// `const TextStyle(... AppColors.X ...)` must drop its `const` keyword.
class AppColors {
  AppColors._();

  // Updated by MyApp before building MaterialApp.
  static Brightness brightness = Brightness.dark;
  static bool get _dark => brightness == Brightness.dark;

  // Resolves the active brightness for a given ThemeMode + OS preference and
  // applies it to the static tokens. Call this in MyApp.build before the
  // MaterialApp is constructed so all descendants see the right shade.
  static void applyThemeMode(ThemeMode mode, Brightness platform) {
    brightness = switch (mode) {
      ThemeMode.system => platform,
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
    };
  }

  // Brand colour — stable across themes.
  static const Color primary = Color(0xFF00E5B4);

  // Surfaces (lowest -> highest elevation)
  static Color get bg =>
      _dark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA);
  static Color get surfaceLow =>
      _dark ? const Color(0xFF0E0E0E) : const Color(0xFFF4F4F4);
  static Color get surface =>
      _dark ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
  static Color get surfaceHigh =>
      _dark ? const Color(0xFF161616) : const Color(0xFFEEEEEE);
  static Color get surfaceMuted =>
      _dark ? const Color(0xFF1A1A1A) : const Color(0xFFE5E5E5);
  static Color get surfaceElevated =>
      _dark ? const Color(0xFF1E1E1E) : const Color(0xFFE0E0E0);
  static Color get surfacePill =>
      _dark ? const Color(0xFF222222) : const Color(0xFFD5D5D5);

  // Lines & borders
  static Color get border =>
      _dark ? const Color(0xFF181818) : const Color(0xFFE8E8E8);
  static Color get borderStrong =>
      _dark ? const Color(0xFF2E2E2E) : const Color(0xFFCCCCCC);

  // Text (lightest -> darkest in dark mode; reversed for light mode)
  static Color get textPrimary => _dark ? Colors.white : const Color(0xFF0F0F0F);
  static Color get textBody =>
      _dark ? const Color(0xFFCCCCCC) : const Color(0xFF333333);
  static Color get textBodyAlt =>
      _dark ? const Color(0xFFBFBFBF) : const Color(0xFF444444);
  static Color get textSecondary =>
      _dark ? const Color(0xFFAAAAAA) : const Color(0xFF555555);
  static Color get textMuted =>
      _dark ? const Color(0xFF999999) : const Color(0xFF666666);
  static Color get textPlaceholder =>
      _dark ? const Color(0xFF888888) : const Color(0xFF777777);
  static Color get textHint =>
      _dark ? const Color(0xFF666666) : const Color(0xFF888888);
  static Color get textDisabled =>
      _dark ? const Color(0xFF555555) : const Color(0xFF999999);
  static Color get textFaint =>
      _dark ? const Color(0xFF444444) : const Color(0xFFAAAAAA);
  static Color get textFainter =>
      _dark ? const Color(0xFF3A3A3A) : const Color(0xFFB5B5B5);
}
