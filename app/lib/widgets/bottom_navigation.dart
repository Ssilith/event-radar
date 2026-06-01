import 'package:event_radar/core/models/page.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:motion_tab_bar_v2/motion-tab-bar.dart';
import 'package:motion_tab_bar_v2/motion-tab-controller.dart';

class BottomNavigation extends StatelessWidget {
  final MotionTabBarController? controller;
  final Function(int) onTap;
  const BottomNavigation({
    super.key,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    // MotionTabBar caches the active tab as a *label string* in its own State
    // and only refreshes via the controller's onTabChange callback. Self-
    // assigning controller.index inside didChangeDependencies turned out to be
    // unreliable in practice (the package's internal animation state can lag
    // behind), so we just force a remount by keying on the locale. The
    // `initialSelectedTab` is seeded from the controller's current index so
    // the user stays on the same tab through the remount.
    final localeCode = Localizations.localeOf(context).languageCode;
    final currentPage = Page.values[controller?.index ?? 0];
    // MotionTabBar doesn't forward `key` to its StatefulWidget super, so wrap
    // it in a KeyedSubtree to make remount-on-locale actually take effect.
    return KeyedSubtree(
      key: ValueKey('motion-tab-bar-$localeCode'),
      child: MotionTabBar(
        controller: controller,
        initialSelectedTab: currentPage.label(l),
        labels: Page.values.map((p) => p.label(l)).toList(),
        icons: Page.values.map((p) => p.iconData).toList(),
        tabSize: 52,
        tabBarHeight: 62,
        textStyle: TextStyle(
          fontSize: 14,
          color: cs.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        tabBarColor: cs.surfaceContainerHigh,
        tabSelectedColor: cs.primary,
        tabIconColor: cs.onSurface.withValues(alpha: 0.5),
        tabIconSize: 30,
        tabIconSelectedColor: cs.surfaceContainerHigh,
        tabIconSelectedSize: 30,
        onTabItemSelected: onTap,
      ),
    );
  }
}
