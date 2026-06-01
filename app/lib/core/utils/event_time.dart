import 'package:event_radar/core/models/event.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final _log = Logger('EventTime');

bool _tzInitialized = false;
String? _phoneIanaName;

void initVenueTime() {
  if (_tzInitialized) return;
  tzdata.initializeTimeZones();
  _tzInitialized = true;
  // Phone tz lookup is async and only used for the details-screen suffix,
  // so we fire-and-forget — formatting works fine without it.
  _loadPhoneTz();
}

Future<void> _loadPhoneTz() async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    _phoneIanaName = info.identifier;
  } catch (e, s) {
    _log.warning('phone tz lookup failed', e, s);
    _phoneIanaName = null;
  }
}

String? phoneTzShortName() {
  final name = _phoneIanaName;
  if (name == null || name.isEmpty) return null;
  final parts = name.split('/');
  return parts.last.replaceAll('_', ' ');
}

tz.Location venueLocation(String? tzName) {
  final name = (tzName ?? '').trim();
  if (name.isEmpty) return tz.UTC;
  try {
    return tz.getLocation(name);
  } on tz.LocationNotFoundException {
    return tz.UTC;
  }
}

tz.TZDateTime _inVenueTz(DateTime utc, String? tzName) =>
    tz.TZDateTime.from(utc, venueLocation(tzName));

String formatEventTime(
  Event event,
  String pattern, {
  DateTime? when,
  String? locale,
}) {
  final venue = _inVenueTz(when ?? event.start, event.timezone);
  return DateFormat(pattern, locale).format(venue);
}

DateTime eventWallClock(Event event, {DateTime? when}) {
  final venue = _inVenueTz(when ?? event.start, event.timezone);
  // Strip tz so calendar-day comparisons (DateUtils.isSameDay etc) work in
  // the venue's local frame without surprises from UTC offsets.
  return DateTime(
    venue.year,
    venue.month,
    venue.day,
    venue.hour,
    venue.minute,
    venue.second,
  );
}

DateTime nowInVenueTz(String? tzName) {
  final now = tz.TZDateTime.now(venueLocation(tzName));
  return DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
    now.second,
  );
}

// Where in its own lifecycle an event sits, computed in the venue's tz so
// the answer matches what a local attendee would expect. Use via
// `event.status` from the EventTiming extension below.
enum EventStatus {
  // Hasn't started yet.
  upcoming,
  // Started and not yet ended. Multi-day events live here while running.
  ongoing,
  // End time (or start, for end-less events) has passed.
  past,
}

// Extension that exposes timezone-aware lifecycle checks as if they were
// getters on Event. Lives in this file (not event.dart) because it relies on
// the venue-tz helpers above — placing it on the model directly would force
// the model to import flutter/timezone packages.
extension EventTiming on Event {
  // Computes start + end (with end falling back to start for instant events)
  // once, in the venue's wall-clock frame. Other getters reuse this so the
  // "what's the effective end?" logic lives in one place.
  ({DateTime start, DateTime end}) get wallClockRange {
    final s = eventWallClock(this);
    final e = end != null ? eventWallClock(this, when: end) : s;
    return (start: s, end: e);
  }

  EventStatus get status {
    final s = eventWallClock(this);
    // Events without an explicit end roll over at midnight of their start
    // day — an 18:00 concert with no end reads as ongoing from 18:00 until
    // midnight; all-day (00:00 start) events get the full 24 hours. With
    // an explicit end, we honour it as-is. Note: this is intentionally NOT
    // shared with wallClockRange — that getter describes the event's actual
    // extent, used by isMultiDay / isHappeningToday, where a midnight roll
    // would misclassify an instant evening event as multi-day.
    final effectiveEnd = end != null
        ? eventWallClock(this, when: end)
        : DateTime(s.year, s.month, s.day + 1);
    final now = nowInVenueTz(timezone);
    if (effectiveEnd.isBefore(now)) return EventStatus.past;
    // Upcoming only until the event first begins. Once it has started a
    // multi-day event stays ongoing for its whole run — it does not flip back
    // to "upcoming" each morning until the original start time. This matches
    // how later days now read as all-day rather than re-opening at, say, 18:00.
    if (s.isAfter(now)) return EventStatus.upcoming;
    return EventStatus.ongoing;
  }

  bool get isPast => status == EventStatus.past;
  bool get isOngoing => status == EventStatus.ongoing;
  bool get isUpcoming => status == EventStatus.upcoming;

  // True when the event's range overlaps today's calendar day in the venue's
  // timezone. Distinct from `isOngoing` — a festival starting tomorrow is
  // happening tomorrow, not today; a multi-week exhibition is happening today
  // even if it started a week ago and ends next week.
  bool get isHappeningToday {
    final r = wallClockRange;
    final now = nowInVenueTz(timezone);
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return r.start.isBefore(dayEnd) && !r.end.isBefore(dayStart);
  }

  // True when the event's start has no time-of-day component (00:00 in the
  // venue's tz), matching the heuristic eventDurationLabel uses to render
  // "All day". Multi-day events whose start lands at midnight count as
  // all-day. Used to suppress the "ongoing" status for events with no proper
  // hours — there's no meaningful "in progress" window to be inside of.
  bool get isAllDay {
    final s = eventWallClock(this);
    return s.hour == 0 && s.minute == 0;
  }

  // True when start and end fall on different calendar days in the venue's
  // timezone. Used by row/card widgets to swap "HH:mm" (the original start
  // time, often on a past day) for an end-date pointer when the event spans
  // today.
  bool get isMultiDay {
    if (end == null) return false;
    final r = wallClockRange;
    return r.start.year != r.end.year ||
        r.start.month != r.end.month ||
        r.start.day != r.end.day;
  }
}

bool venueTzDiffersFromPhone(String? tzName) {
  final loc = venueLocation(tzName);
  if (loc == tz.UTC && (tzName ?? '').isEmpty) return false;
  final now = DateTime.now().toUtc();
  final venueOffset = tz.TZDateTime.from(now, loc).timeZoneOffset;
  return venueOffset != DateTime.now().timeZoneOffset;
}

// Short human label for the event's start: hour:minute when the source
// carried a wall-clock time, "All day" otherwise. Lives here (not on the
// Event model) so the model stays free of UI dependencies. Callers pass the
// localised "All day" string via [labels].
class DurationLabels {
  final String allDay;
  const DurationLabels({required this.allDay});
}

String? eventDurationLabel(
  Event event, {
  required DurationLabels labels,
  String? locale,
}) {
  // Time-or-all-day, regardless of multi-day spans. A festival that starts
  // 20:00 still reads as "20:00" — duration is conveyed elsewhere (date
  // range on the details screen). Date-only feeds parse to midnight in the
  // venue tz, which we treat as "all day".
  final wall = eventWallClock(event);
  if (wall.hour == 0 && wall.minute == 0) return labels.allDay;
  return formatEventTime(event, 'HH:mm', locale: locale);
}

// Compact time label for an event as it reads *right now*. A multi-day event
// only carries a meaningful start time on its first day; once it is under way,
// every later day (including the last) is simply ongoing, so we render
// "All day" rather than the now-past start time. Events that start today or
// later — and every single-day event — fall through to their real start time.
String eventTodayLabel(
  Event event, {
  required DurationLabels labels,
  String? locale,
}) {
  if (event.isMultiDay) {
    final start = eventWallClock(event);
    final now = nowInVenueTz(event.timezone);
    final startDay = DateTime(start.year, start.month, start.day);
    final today = DateTime(now.year, now.month, now.day);
    if (today.isAfter(startDay)) return labels.allDay;
  }
  return eventDurationLabel(event, labels: labels, locale: locale) ?? '';
}

String venueTzShortName(String? tzName) {
  final loc = venueLocation(tzName);
  if (loc == tz.UTC) return 'UTC';
  // IANA zone last segment is usually the city — e.g. 'Europe/Warsaw' -> 'Warsaw'.
  final parts = loc.name.split('/');
  return parts.last.replaceAll('_', ' ');
}
