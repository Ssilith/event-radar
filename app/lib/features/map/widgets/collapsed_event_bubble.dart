import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

//* Minimized bubble for a collapsed selected-event card (tap reopens, X closes)
class CollapsedEventBubble extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback onClose;
  const CollapsedEventBubble({
    super.key,
    required this.event,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = event.category.color;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                //* Same as an unselected map pin: a category-tinted disc with a
                //* category ring + icon
                color: catColor.withValues(alpha: 0.14),
                border: Border.all(color: catColor, width: 2),
              ),
              child: Icon(event.category.iconData, size: 26, color: catColor),
            ),
          ),
        ),
        Positioned(
          right: -2,
          top: -2,
          child: Material(
            color: AppColors.surfaceElevated,
            //* Red ring + icon to read as a "dismiss" action
            shape: const CircleBorder(
              side: BorderSide(color: Color(0xFFEF5350), width: 1.2),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: Color(0xFFEF5350),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
