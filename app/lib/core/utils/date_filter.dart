import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';

//* Date buckets for the Discover chips (Map always uses `all`)
enum DateFilter { today, week, month, all, past }

extension DateFilterExt on DateFilter {
  //* Localized chip label
  String label(AppL10n l) => switch (this) {
    DateFilter.today => l.filterToday,
    DateFilter.week => l.filterWeek,
    DateFilter.month => l.filterMonth,
    DateFilter.all => l.filterAll,
    DateFilter.past => l.filterPast,
  };

  //* Whether an event falls in this bucket, by its full venue-local range
  //* (shared by Discover + Map so they can't drift apart)
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
      DateFilter.week => _overlaps(
        start,
        end,
        now,
        now.add(const Duration(days: 7)),
      ),
      DateFilter.month => _overlaps(
        start,
        end,
        now,
        now.add(const Duration(days: 30)),
      ),
      //* All = every non-past event (past lives behind the Past chip)
      DateFilter.all => !end.isBefore(now),
      //* Past only once the end has actually gone by (ongoing stays out)
      DateFilter.past => end.isBefore(now),
    };
  }
}

//* True when [start, end] overlaps [windowStart, windowEnd) at all
bool _overlaps(
  DateTime start,
  DateTime end,
  DateTime windowStart,
  DateTime windowEnd,
) => start.isBefore(windowEnd) && !end.isBefore(windowStart);
