import 'package:flutter/material.dart';

//* Brightness-aware colour tokens; non-const getters resolve per AppColors.brightness
class AppColors {
  AppColors._();

  //* Active brightness, set by MyApp before building MaterialApp
  static Brightness brightness = Brightness.dark;
  static bool get _dark => brightness == Brightness.dark;

  //* Resolve + apply the active brightness for a ThemeMode + OS preference
  static void applyThemeMode(ThemeMode mode, Brightness platform) {
    brightness = switch (mode) {
      ThemeMode.system => platform,
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
    };
  }

  //* Brand colour — stable across themes
  static const Color primary = Color(0xFF00E5B4);

  //* Text/icon colour on a primary fill: black on the bright dark-mode mint,
  //* white on the darker (Material-derived) light-mode primary.
  static Color get onPrimary => _dark ? Colors.black : Colors.white;

  //* Surfaces (lowest → highest elevation). Light mode uses a cool slate
  //* undertone with white cards that lift off a faint grey-blue page.
  static Color get bg =>
      _dark ? const Color(0xFF0A0A0A) : const Color(0xFFF2F5F9);
  static Color get surfaceLow =>
      _dark ? const Color(0xFF0E0E0E) : const Color(0xFFEAEEF4);
  static Color get surface =>
      _dark ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
  static Color get surfaceHigh =>
      _dark ? const Color(0xFF161616) : const Color(0xFFE7ECF2);
  static Color get surfaceMuted =>
      _dark ? const Color(0xFF1A1A1A) : const Color(0xFFDDE3EB);
  static Color get surfaceElevated =>
      _dark ? const Color(0xFF1E1E1E) : const Color(0xFFD5DCE5);
  static Color get surfacePill =>
      _dark ? const Color(0xFF222222) : const Color(0xFFCBD3DE);

  //* Lines & borders
  static Color get border =>
      _dark ? const Color(0xFF181818) : const Color(0xFFE2E7EE);
  static Color get borderStrong =>
      _dark ? const Color(0xFF2E2E2E) : const Color(0xFFC4CDD9);

  //* Text (lightest → darkest in dark mode; reversed in light). Light mode
  //* uses deep slate tones rather than pure black/grey for a softer, premium feel.
  static Color get textPrimary => _dark ? Colors.white : const Color(0xFF101620);
  static Color get textBody =>
      _dark ? const Color(0xFFCCCCCC) : const Color(0xFF2B333F);
  static Color get textBodyAlt =>
      _dark ? const Color(0xFFBFBFBF) : const Color(0xFF38414E);
  static Color get textSecondary =>
      _dark ? const Color(0xFFAAAAAA) : const Color(0xFF4E5765);
  static Color get textMuted =>
      _dark ? const Color(0xFF999999) : const Color(0xFF646E7C);
  static Color get textPlaceholder =>
      _dark ? const Color(0xFF888888) : const Color(0xFF77808D);
  static Color get textHint =>
      _dark ? const Color(0xFF666666) : const Color(0xFF8B95A1);
  static Color get textDisabled =>
      _dark ? const Color(0xFF555555) : const Color(0xFFA7B0BC);
  static Color get textFaint =>
      _dark ? const Color(0xFF444444) : const Color(0xFFBEC6D0);
  static Color get textFainter =>
      _dark ? const Color(0xFF3A3A3A) : const Color(0xFFCED5DD);
}
