import 'package:event_radar/core/models/distance_unit.dart';
import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/html_text.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class NearbyEventRow extends StatelessWidget {
  final Event event;
  final Position? userPosition;
  final bool isToday;
  final VoidCallback onTap;
  final VoidCallback onOpenDetails;

  const NearbyEventRow({
    super.key,
    required this.event,
    required this.userPosition,
    required this.isToday,
    required this.onTap,
    required this.onOpenDetails,
  });

  String? _distanceLabel() {
    final pos = userPosition;
    if (pos == null) return null;
    final km = event.distanceTo(pos.latitude, pos.longitude);
    if (km == null) return null;
    return SettingsService.instance.distanceUnit.value.format(km);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final catColor = event.category.color;
    final distance = _distanceLabel();
    final durationLabels = DurationLabels(allDay: l.allDay);
    // In light mode every row uses the more saturated "today" decoration so
    // tiles feel consistent on a light surface; dark mode keeps the original
    // toned-down look for non-today rows so today still stands out.
    final showTodayStyle =
        isToday || AppColors.brightness == Brightness.light;

    return InkWell(
      onTap: onTap,
      onLongPress: onOpenDetails,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
        decoration: BoxDecoration(
          color: showTodayStyle ? primary.withValues(alpha: 0.05) : null,
          border: Border(
            bottom: BorderSide(color: AppColors.surfaceMuted),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: showTodayStyle
                    ? catColor.withValues(alpha: 0.3)
                    : catColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: showTodayStyle
                      ? catColor
                      : catColor.withValues(alpha: 0.35),
                  width: showTodayStyle ? 1.5 : 1,
                ),
              ),
              child: Icon(event.category.iconData, size: 18, color: catColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isToday) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l.bucketToday.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: HtmlText(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 11, color: primary),
                      const SizedBox(width: 3),
                      Text(
                        // Mirror the featured card: when the event is on today
                        // (single- or multi-day) show just the start time, or
                        // "All day". Otherwise show date + time. This drops the
                        // old "→ end date" arrow for multi-day events.
                        isToday
                            ? eventTodayLabel(
                                event,
                                labels: durationLabels,
                                locale: locale,
                              )
                            : formatEventTime(event, 'd MMM • HH:mm', locale: locale),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                      if (event.venue != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            event.venue!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (distance != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  distance,
                  style: TextStyle(
                    color: primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textFainter,
              ),
          ],
        ),
      ),
    );
  }
}
