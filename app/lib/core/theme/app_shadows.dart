import 'package:flutter/material.dart';

//* Drop-shadow presets — identical in light and dark mode.
//* Temporarily disabled app-wide: both presets are empty for a flat look.
class AppShadows {
  AppShadows._();

  //* Tiny lift for chips/badges
  static const List<BoxShadow> subtle = [];

  //* Stronger lift for floating overlays (sheets, popups)
  static const List<BoxShadow> overlay = [];
}
