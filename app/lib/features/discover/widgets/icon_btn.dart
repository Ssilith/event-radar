import 'package:event_radar/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

//* Small tinted icon button used in the discover header
class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const IconBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20, color: AppColors.textSecondary),
      onPressed: onTap,
      splashRadius: 20,
    );
  }
}
