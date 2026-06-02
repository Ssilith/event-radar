import 'package:event_radar/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

//* Round map action button (fit-to-events / my-location), dimmed when disabled
class MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const MapFab({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final enabled = onTap != null;
    return Material(
      color: AppColors.surfaceHigh,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? primary : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}
