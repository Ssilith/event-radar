import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/utils/event_time.dart';

//* Collapse same title+venue events with overlapping date ranges
List<Event> dedupeOverlapping(List<Event> events) {
  final groups = <String, List<Event>>{};
  for (final e in events) {
    final key =
        '${e.title.trim().toLowerCase()}|'
        '${(e.venue ?? '').trim().toLowerCase()}';
    (groups[key] ??= []).add(e);
  }

  final result = <Event>[];
  for (final group in groups.values) {
    if (group.length == 1) {
      result.add(group.first);
      continue;
    }
    //* One representative per cluster of overlapping ranges
    final reps = <Event>[];
    for (final e in group) {
      final r = e.wallClockRange;
      var merged = false;
      for (var i = 0; i < reps.length; i++) {
        final rr = reps[i].wallClockRange;
        //* Inclusive overlap: ranges intersect or touch at an endpoint
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

//* Event duration in ms (used to pick the widest of overlapping copies)
int _spanMs(Event e) {
  final r = e.wallClockRange;
  return r.end.difference(r.start).inMilliseconds;
}

//* Map markers are spatial, so a same title+venue event must be a single pin
List<Event> dedupeForMap(List<Event> events) {
  final byPlace = <String, Event>{};
  for (final e in dedupeOverlapping(events)) {
    final key =
        '${e.title.trim().toLowerCase()}|'
        '${(e.venue ?? '').trim().toLowerCase()}';
    final existing = byPlace[key];
    if (existing == null || e.start.isBefore(existing.start)) {
      byPlace[key] = e;
    }
  }
  return byPlace.values.toList();
}
