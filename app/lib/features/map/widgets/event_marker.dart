import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class EventMarker extends StatelessWidget {
  final EventCategory category;
  final bool isSelected;
  final bool isToday;

  const EventMarker({
    super.key,
    required this.category,
    required this.isSelected,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    final filled = isSelected || isToday;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: filled ? color : AppColors.surfaceHigh,
        shape: BoxShape.circle,
        border: Border.all(
          color: isToday ? Colors.white : color,
          width: isSelected ? 2.5 : (isToday ? 2 : 1.5),
        ),
        boxShadow: [
          if (isToday)
            BoxShadow(
              blurRadius: 12,
              spreadRadius: 1,
              color: color.withValues(alpha: 0.6),
            )
          else
            const BoxShadow(blurRadius: 4, color: Colors.black54),
        ],
      ),
      child: Icon(
        category.iconData,
        size: isSelected ? 22 : (isToday ? 20 : 16),
        color: filled ? Colors.black : color,
      ),
    );
  }
}
