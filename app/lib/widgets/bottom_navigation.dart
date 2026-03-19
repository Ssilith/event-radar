import 'package:bnb_flutter/bnb_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BnbWidget(
      selectedIndex: selectedIndex,
      style: BnbStyle(
        iconSize: const Size(24, 24),
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      items: [
        BnbItem(iconData: MdiIcons.circleSlice8),
        BnbItem(iconData: MdiIcons.heart),
        BnbItem(iconData: MdiIcons.mapMarker),
      ],
      onTap: onTap,
    );
  }
}
