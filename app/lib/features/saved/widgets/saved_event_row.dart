import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/theme/app_shadows.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/features/event_details/event_details_screen.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/html_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SavedEventRow extends StatelessWidget {
  final Event event;
  final VoidCallback onRemove;
  const SavedEventRow({super.key, required this.event, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isPast = event.start.isBefore(DateTime.now().toUtc());
    final eventLocal = eventWallClock(event);
    final catColor = event.category.color;

    return InkWell(
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
      ),
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
                  onTap: onRemove,
                  child: Icon(
                    Icons.bookmark_rounded,
                    size: 19,
                    color: primary,
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
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: AppColors.textFainter,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
