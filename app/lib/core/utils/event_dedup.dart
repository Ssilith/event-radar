import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/utils/event_time.dart';

// Some sources list the same multi-day event several times with staggered start
// dates but the same end (e.g. a 3-day fair indexed as 27–29, 28–29 and 29–29),
// so the copies all overlap and a single day can show the event two or three
// times. This collapses entries that are really the SAME occurrence — identical
// title + venue whose venue-local date ranges overlap — down to one, keeping the
// widest span. Entries that merely share a name but fall on non-overlapping
// dates (a weekly market on different Saturdays) are left untouched, so genuine
// recurrences still show one row per date.
List<Event> dedupeOverlapping(List<Event> events) {
  final groups = <String, List<Event>>{};
  for (final e in events) {
    final key = '${e.title.trim().toLowerCase()}|'
        '${(e.venue ?? '').trim().toLowerCase()}';
    (groups[key] ??= []).add(e);
  }

  final result = <Event>[];
  for (final group in groups.values) {
    if (group.length == 1) {
      result.add(group.first);
      continue;
    }
    // Keep one representative per cluster of overlapping ranges.
    final reps = <Event>[];
    for (final e in group) {
      final r = e.wallClockRange;
      var merged = false;
      for (var i = 0; i < reps.length; i++) {
        final rr = reps[i].wallClockRange;
        // Inclusive overlap: ranges intersect or touch at an endpoint.
        final overlaps = !r.start.isAfter(rr.end) && !rr.start.isAfter(r.end);
        if (overlaps) {
          if (_spanMs(e) > _spanMs(reps[i])) reps[i] = e;
          merged = true;
          break;
        }
      }
      if (!merged) reps.add(e);
    }
    result.addAll(reps);
  }
  return result;
}

int _spanMs(Event e) {
  final r = e.wallClockRange;
  return r.end.difference(r.start).inMilliseconds;
}
