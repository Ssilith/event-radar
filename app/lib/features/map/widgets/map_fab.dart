import 'package:event_radar/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  const MapFab({super.key, required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: AppColors.surfaceHigh,
        shape: const CircleBorder(),
        elevation: 4,
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
      ),
    );
  }
}
