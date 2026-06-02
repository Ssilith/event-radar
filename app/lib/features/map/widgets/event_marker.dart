import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

//* Category pin on the map; emphasised for selected/today events
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
    //* Light mode uses the today style for all markers (faint ones vanish on tiles)
    final showTodayStyle =
        isToday || AppColors.brightness == Brightness.light;
    final filled = isSelected || showTodayStyle;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: filled ? color : AppColors.surfaceHigh,
        shape: BoxShape.circle,
        border: Border.all(
          color: showTodayStyle ? Colors.white : color,
          width: isSelected ? 2.5 : (showTodayStyle ? 2 : 1.5),
        ),
        boxShadow: [
          if (showTodayStyle)
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
        size: isSelected ? 22 : (showTodayStyle ? 20 : 16),
        //* On a filled pin the icon must contrast the fill: white on the deep
        //* light-mode shade, black on the pale dark-mode pastel
        color: filled
            ? (AppColors.brightness == Brightness.light
                  ? Colors.white
                  : Colors.black)
            : color,
      ),
    );
  }
}
