import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

//* Category pin on the map; emphasised only when selected
class EventMarker extends StatelessWidget {
  final EventCategory category;
  final bool isSelected;

  const EventMarker({
    super.key,
    required this.category,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    //* Selected: solid category fill with an onPrimary icon (same as the
    //* collapsed bubble). Unselected: a category-tinted surface disc with a
    //* category ring + icon.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isSelected
            ? color
            : Color.alphaBlend(
                color.withValues(alpha: 0.14),
                AppColors.surface,
              ),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: isSelected ? 2.5 : 2),
      ),
      child: Icon(
        category.iconData,
        size: isSelected ? 22 : 16,
        color: isSelected ? AppColors.onPrimary : color,
      ),
    );
  }
}
