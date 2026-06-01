import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/html_text.dart';
import 'package:flutter/material.dart';

// Compact info card shown over the map when a marker (or nearby event) is
// selected. Header has collapse + close icons; footer has Directions + Details
// buttons.
class SelectedEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onClose;
  final VoidCallback onCollapse;
  final VoidCallback onDirections;
  final VoidCallback onDetails;

  const SelectedEventCard({
    super.key,
    required this.event,
    required this.onClose,
    required this.onCollapse,
    required this.onDirections,
    required this.onDetails,
  });

  // Mirror the featured card: while the event is on today (single- or
  // multi-day) show just the start time, or "All day". The original start date
  // isn't useful on a map being viewed today, and for multi-day events it
  // would point at the past. Other events keep the "EEE d MMM, HH:mm" line.
  String _formatWhen(String locale, DurationLabels labels) {
    if (event.isHappeningToday) {
      return eventTodayLabel(event, labels: labels, locale: locale);
    }
    return formatEventTime(event, 'EEE d MMM, HH:mm', locale: locale);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final catColor = event.category.color;
    final durationLabels = DurationLabels(allDay: l.allDay);

    return Material(
      color: AppColors.surface,
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onDetails,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      event.category.iconData,
                      size: 16,
                      color: catColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HtmlText(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.remove_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: onCollapse,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    tooltip: l.collapse,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    tooltip: l.dismiss,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 12, color: primary),
                  const SizedBox(width: 4),
                  Text(
                    _formatWhen(locale, durationLabels),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (event.venue != null) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.location_on_rounded, size: 12, color: primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.venue!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: Text(l.directions),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: Text(l.details),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
