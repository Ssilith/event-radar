import 'package:event_radar/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

// Theme-aware drop-shadow presets. Light mode needs more visible shadows
// because surfaces share similar tones; dark mode keeps them subtle so the
// existing tonal hierarchy isn't muddied. Resolves against AppColors.brightness
// at the time of read, so consumers should re-read inside a build() that's
// known to rebuild on theme change.
class AppShadows {
  AppShadows._();

  static bool get _dark => AppColors.brightness == Brightness.dark;

  // Tiny lift for chips/badges/small inline accents. Dark-mode is intentionally
  // empty — small elements already pop against the dark bg, and adding a
  // shadow there just smudges them.
  static List<BoxShadow> get subtle => _dark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ];

  // Soft lift for static cards (e.g. discover carousel tiles).
  static List<BoxShadow> get card => _dark
      ? const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ];

  // Stronger lift for floating overlays (sheets, popups).
  static List<BoxShadow> get overlay => _dark
      ? const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ];
}
