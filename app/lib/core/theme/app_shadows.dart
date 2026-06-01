import 'package:flutter/material.dart';

//* Drop-shadow presets — identical in light and dark mode
class AppShadows {
  AppShadows._();

  //* Tiny lift for chips/badges
  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  //* Stronger lift for floating overlays (sheets, popups)
  static const List<BoxShadow> overlay = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2)),
  ];
}
