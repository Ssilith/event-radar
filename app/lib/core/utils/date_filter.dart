import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';

enum DateFilter { today, week, month, all, past }

extension DateFilterExt on DateFilter {
  String label(AppL10n l) => switch (this) {
        DateFilter.today => l.filterToday,
        DateFilter.week => l.filterWeek,
        DateFilter.month => l.filterMonth,
        DateFilter.all => l.filterAll,
        DateFilter.past => l.filterPast,
      };

  // Whether [event] falls under this filter, judged by the event's venue-local
  // wall-clock *range* so multi-day events are matched by their whole span
  // (a festival counts as long as any of its days overlaps the window, and
  // stays out of "past" until its end has actually gone by). Shared by Discover
  // (which exposes the chips) and Map (which always shows `all`) so the two
  // screens can never drift out of sync.
  bool matches(Event event) {
    final r = event.wallClockRange;
    final start = r.start;
    final end = r.end;
    final now = nowInVenueTz(event.timezone);
    return switch (this) {
      DateFilter.today => _overlaps(
          start,
          end,
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
        ),
      DateFilter.week =>
        _overlaps(start, end, now, now.add(const Duration(days: 7))),
      DateFilter.month =>
        _overlaps(start, end, now, now.add(const Duration(days: 30))),
      // "All" means every non-past event — past events are reachable through
      // the dedicated Past chip.
      DateFilter.all => !end.isBefore(now),
      // A multi-day event is only past once its end has passed; ongoing events
      // stay out of this bucket.
      DateFilter.past => end.isBefore(now),
    };
  }
}

// True when [start, end] overlaps [windowStart, windowEnd) at all.
bool _overlaps(
  DateTime start,
  DateTime end,
  DateTime windowStart,
  DateTime windowEnd,
) =>
    start.isBefore(windowEnd) && !end.isBefore(windowStart);
