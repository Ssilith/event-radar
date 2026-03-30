import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
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
      initialSelectedTab: "Discover",
      labels: const ["Discover", "Saved", "Map"],
      icons: const [MdiIcons.compass, MdiIcons.heart, MdiIcons.mapMarker],
      tabSize: 52,
      tabBarHeight: 62,
      textStyle: TextStyle(
        fontSize: 11,
        color: cs.primary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      tabBarColor: cs.surfaceContainerHigh,
      tabSelectedColor: cs.primary,
      tabIconColor: cs.onSurface.withValues(alpha: 0.5),
      tabIconSelectedColor: cs.surfaceContainerHigh,
      onTabItemSelected: onTap,
    );
  }
}
