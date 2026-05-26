import 'package:flutter/material.dart';

// Spacing and shape tokens. Use these instead of raw numeric literals so the
// app's rhythm is enforced from one place.
class AppSpacing {
  AppSpacing._();

  // Base scale — most paddings and gaps come from this 4-pt grid.
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 24;
  static const double huge = 32;

  // Common screen-edge padding (e.g. list rows, sections).
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets listRowPadding =
      EdgeInsets.fromLTRB(xl, 14, lg, 14);
}

class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 16;
  static const double xxl = 20;
  static const double pill = 22;
  static const double circle = 999;
}

class AppGap {
  AppGap._();

  static const SizedBox xxs = SizedBox(height: AppSpacing.xxs, width: AppSpacing.xxs);
  static const SizedBox xs = SizedBox(height: AppSpacing.xs, width: AppSpacing.xs);
  static const SizedBox sm = SizedBox(height: AppSpacing.sm, width: AppSpacing.sm);
  static const SizedBox md = SizedBox(height: AppSpacing.md, width: AppSpacing.md);
  static const SizedBox lg = SizedBox(height: AppSpacing.lg, width: AppSpacing.lg);
  static const SizedBox xl = SizedBox(height: AppSpacing.xl, width: AppSpacing.xl);
  static const SizedBox xxl = SizedBox(height: AppSpacing.xxl, width: AppSpacing.xxl);
}
