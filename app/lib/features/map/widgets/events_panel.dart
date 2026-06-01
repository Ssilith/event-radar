import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/features/map/widgets/nearby_event_row.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

// The events chip's expanded panel — header + scrollable list of nearby events.
class EventsPanel extends StatelessWidget {
  final List<Event> events;
  final int todayCount;
  final Position? userPosition;
  final VoidCallback onCollapse;
  final ValueChanged<Event> onSelect;
  final ValueChanged<Event> onOpenDetails;

  const EventsPanel({
    super.key,
    required this.events,
    required this.todayCount,
    required this.userPosition,
    required this.onCollapse,
    required this.onSelect,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    return Material(
      color: AppColors.surface,
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 6, 6),
                child: Row(
                  children: [
                    Icon(Icons.event_note_rounded, size: 16, color: primary),
                    const SizedBox(width: 8),
                    Text(
                      l.events,
                      style: GoogleFonts.syne(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      todayCount > 0
                          ? l.todayCount(todayCount)
                          : l.upcomingCount(events.length),
                      style: TextStyle(color: primary, fontSize: 12),
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
                  ],
                ),
              ),
              Divider(color: AppColors.surfacePill, height: 1),
              if (events.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                      l.mapNoEvents,
                      style: TextStyle(color: AppColors.textPlaceholder),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: events.length,
                    itemBuilder: (_, i) => NearbyEventRow(
                      event: events[i],
                      userPosition: userPosition,
                      isToday: events[i].isHappeningToday,
                      onTap: () => onSelect(events[i]),
                      onOpenDetails: () => onOpenDetails(events[i]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
