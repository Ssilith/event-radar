import 'package:event_radar/core/models/distance_unit.dart';
import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/theme/app_shadows.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/widgets/html_text.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

//* All-Events list row: date badge, title, venue, category icon + time + price (muted), save
class EventRow extends StatelessWidget {
  final Event event;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onOpen;
  //* When set (and the event has coords), shows a distance pill instead of a chevron
  final Position? userPosition;

  const EventRow({
    super.key,
    required this.event,
    required this.isSaved,
    required this.onToggleSave,
    required this.onOpen,
    this.userPosition,
  });

  //* Formatted distance pill text, or null without a position/coords
  String? _distanceLabel() {
    final pos = userPosition;
    if (pos == null) return null;
    final km = event.distanceTo(pos.latitude, pos.longitude);
    if (km == null) return null;
    return SettingsService.instance.distanceUnit.value.format(km);
  }

  //* Trailing widget: distance pill when known, else a chevron
  Widget _buildTrailing(Color primary) {
    final distance = _distanceLabel();
    if (distance == null) {
      return Icon(
        Icons.chevron_right_rounded,
        size: 17,
        color: AppColors.textFainter,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        distance,
        style: TextStyle(
          color: primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isPast = event.isPast;
    final isHappeningToday = !isPast && event.isHappeningToday;
    //* Multi-day events spanning today show today's date in the badge
    final badgeDate = isHappeningToday
        ? nowInVenueTz(event.timezone)
        : eventWallClock(event);
    final catColor = event.category.color;
    //* Start hour on day one; "All day" for all-day events and later multi-day days
    final timeLabel = eventTodayLabel(
      event,
      labels: DurationLabels(allDay: l.allDay),
      locale: locale,
    );
    //* Price (or "Free") to show in the category colour
    final priceLabel = event.isFree
        ? l.free
        : (event.hasPrice ? event.price : null);

    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            //* Date badge
            Container(
              width: 46,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: isPast
                    ? Colors.red.withValues(alpha: 0.09)
                    : primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isPast
                      ? Colors.red.withValues(alpha: 0.25)
                      : primary.withValues(alpha: 0.25),
                ),
                boxShadow: AppShadows.subtle,
              ),
              child: Column(
                children: [
                  Text(
                    isPast
                        ? l.pasShort
                        : DateFormat(
                            'MMM',
                            locale,
                          ).format(badgeDate).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isPast ? Colors.red.shade400 : primary,
                    ),
                  ),
                  Text(
                    '${badgeDate.day}',
                    style: GoogleFonts.syne(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HtmlText(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  if (event.venue != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      event.venue!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                  //* Bottom line: category icon + start hour (or "All day") + price chip
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(event.category.iconData, size: 13, color: catColor),
                      const SizedBox(width: 4),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                      if (priceLabel != null) const SizedBox(width: 10),
                      if (priceLabel != null)
                        Flexible(
                          child: Text(
                            priceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPlaceholder,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggleSave,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        key: ValueKey(isSaved),
                        size: 19,
                        color: isSaved ? primary : AppColors.textFaint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTrailing(primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
