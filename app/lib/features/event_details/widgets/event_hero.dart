import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

//* Category-tinted gradient header with a centred icon and a localized status pill
class EventHero extends StatelessWidget {
  final EventCategory category;
  final EventStatus status;
  const EventHero({super.key, required this.category, required this.status});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    final isPast = status == EventStatus.past;
    //* Localized badge text for the event's lifecycle stage
    final label = switch (status) {
      EventStatus.past => l.past,
      EventStatus.ongoing => l.ongoing,
      EventStatus.upcoming => l.upcoming,
    };
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            category.color.withValues(alpha: 0.45),
            category.color.withValues(alpha: 0.15),
            AppColors.bg,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: category.color.withValues(alpha: 0.10),
              ),
            ),
          ),
          Center(
            child: Icon(
              category.iconData,
              size: 88,
              //* textPrimary so the icon stays visible on either palette
              color: AppColors.textPrimary.withValues(alpha: 0.85),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isPast
                    ? Colors.red.withValues(alpha: 0.2)
                    : primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: isPast ? Colors.red.shade300 : primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
