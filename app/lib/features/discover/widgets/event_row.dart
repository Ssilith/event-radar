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

// Single row in the All Events list — date badge, title, venue, bookmark
// toggle, category dot, chevron.
class EventRow extends StatelessWidget {
  final Event event;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onOpen;
  // When set and the event has coordinates, a distance pill replaces the
  // chevron trailing the row. Pass null (or unset) to hide the pill — used
  // by Saved screen which doesn't always carry a location.
  final Position? userPosition;

  const EventRow({
    super.key,
    required this.event,
    required this.isSaved,
    required this.onToggleSave,
    required this.onOpen,
    this.userPosition,
  });

  String? _distanceLabel() {
    final pos = userPosition;
    if (pos == null) return null;
    final km = event.distanceTo(pos.latitude, pos.longitude);
    if (km == null) return null;
    return SettingsService.instance.distanceUnit.value.format(km);
  }

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
    final isPast = event.start.isBefore(DateTime.now().toUtc());
    final eventLocal = eventWallClock(event);
    final catColor = event.category.color;

    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
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
                        : DateFormat('MMM', locale).format(eventLocal).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isPast ? Colors.red.shade400 : primary,
                    ),
                  ),
                  Text(
                    '${eventLocal.day}',
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
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
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
                const SizedBox(height: 6),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: catColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                _buildTrailing(primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
