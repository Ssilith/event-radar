import 'package:flutter/material.dart';

class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const IconBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20, color: Colors.white70),
      onPressed: onTap,
      tooltip: tooltip,
      splashRadius: 20,
    );
  }
}
