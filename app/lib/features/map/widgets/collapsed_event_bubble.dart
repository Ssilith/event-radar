import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

// The Messenger-style minimized bubble shown after the user collapses the
// selected event card. Tapping it re-expands; the corner X closes.
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
          elevation: 8,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: catColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: catColor.withValues(alpha: 0.4),
                  ),
                ],
              ),
              child: Icon(event.category.iconData, size: 26, color: catColor),
            ),
          ),
        ),
        Positioned(
          right: -4,
          top: -4,
          child: Material(
            color: AppColors.surfacePill,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: SizedBox(
                width: 20,
                height: 20,
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
