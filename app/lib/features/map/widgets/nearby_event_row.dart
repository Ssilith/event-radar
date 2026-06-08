import 'package:event_radar/core/models/distance_unit.dart';
import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/html_text.dart';
import 'package:event_radar/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

//* Event row in the map's events panel, with a distance pill
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

  //* Formatted distance pill text, or null without a position/coords
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

    return InkWell(
      onTap: onTap,
      onLongPress: onOpenDetails,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surfaceMuted)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: catColor.withValues(alpha: 0.4)),
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
                        StatusChip(
                          label: l.bucketToday,
                          background: primary,
                          foreground: AppColors.onPrimary,
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
                        //* Today → time/"All day" (like featured); else date + time
                        isToday
                            ? eventTodayLabel(
                                event,
                                labels: durationLabels,
                                locale: locale,
                              )
                            : formatEventTime(
                                event,
                                'd MMM • HH:mm',
                                locale: locale,
                              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
