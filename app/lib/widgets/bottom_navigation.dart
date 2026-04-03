import 'package:event_radar/utils/page.dart';
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
    return MotionTabBar(
      controller: controller,
      initialSelectedTab: Page.initialPage.value,
      labels: Page.values.map((p) => p.value).toList(),
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
    );
  }
}
