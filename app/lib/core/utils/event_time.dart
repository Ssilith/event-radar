import 'package:event_radar/core/models/event.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final _log = Logger('EventTime');

bool _tzInitialized = false;
String? _phoneIanaName;

//* Initialise the tz database; fire-and-forget the phone tz lookup
void initVenueTime() {
  if (_tzInitialized) return;
  tzdata.initializeTimeZones();
  _tzInitialized = true;
  _loadPhoneTz();
}

//* Cache the phone's IANA timezone (used only for the details-screen suffix)
Future<void> _loadPhoneTz() async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    _phoneIanaName = info.identifier;
  } catch (e, s) {
    _log.warning('phone tz lookup failed', e, s);
    _phoneIanaName = null;
  }
}

//* Short, spaced phone tz name (e.g. "New York"), or null if unknown
String? phoneTzShortName() {
  final name = _phoneIanaName;
  if (name == null || name.isEmpty) return null;
  final parts = name.split('/');
  return parts.last.replaceAll('_', ' ');
}

//* tz.Location for an IANA name, falling back to UTC
tz.Location venueLocation(String? tzName) {
  final name = (tzName ?? '').trim();
  if (name.isEmpty) return tz.UTC;
  try {
    return tz.getLocation(name);
  } on tz.LocationNotFoundException {
    return tz.UTC;
  }
}

//* Convert a UTC instant into the venue's tz
tz.TZDateTime _inVenueTz(DateTime utc, String? tzName) =>
    tz.TZDateTime.from(utc, venueLocation(tzName));

//* Format an event time (or [when]) in the venue's tz with [pattern]
String formatEventTime(
  Event event,
  String pattern, {
  DateTime? when,
  String? locale,
}) {
  final venue = _inVenueTz(when ?? event.start, event.timezone);
  return DateFormat(pattern, locale).format(venue);
}

//* Venue wall-clock time as a tz-free DateTime (for calendar-day comparisons)
DateTime eventWallClock(Event event, {DateTime? when}) {
  final venue = _inVenueTz(when ?? event.start, event.timezone);
  return DateTime(
    venue.year,
    venue.month,
    venue.day,
    venue.hour,
    venue.minute,
    venue.second,
  );
}

//* "Now" in the venue's tz as a tz-free DateTime
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

//* Where an event sits in its lifecycle, judged in the venue's tz
enum EventStatus {
  //* Hasn't started yet
  upcoming,
  //* Started and not yet ended (multi-day events stay here while running)
  ongoing,
  //* End (or start, for end-less events) has passed
  past,
}

//* Timezone-aware lifecycle getters on Event (kept off the model to avoid deps)
extension EventTiming on Event {
  //* Start + end (end falls back to start) in venue wall-clock; reused widely
  ({DateTime start, DateTime end}) get wallClockRange {
    final s = eventWallClock(this);
    final e = end != null ? eventWallClock(this, when: end) : s;
    return (start: s, end: e);
  }

  //* past if ended, upcoming until it first starts, else ongoing for its run
  EventStatus get status {
    final s = eventWallClock(this);
    //* End-less events roll over at next midnight; explicit ends honoured as-is
    final effectiveEnd = end != null
        ? eventWallClock(this, when: end)
        : DateTime(s.year, s.month, s.day + 1);
    final now = nowInVenueTz(timezone);
    if (effectiveEnd.isBefore(now)) return EventStatus.past;
    if (s.isAfter(now)) return EventStatus.upcoming;
    return EventStatus.ongoing;
  }

  bool get isPast => status == EventStatus.past;
  bool get isOngoing => status == EventStatus.ongoing;
  bool get isUpcoming => status == EventStatus.upcoming;

  //* True when the event's range overlaps today's calendar day (venue tz)
  bool get isHappeningToday {
    final r = wallClockRange;
    final now = nowInVenueTz(timezone);
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return r.start.isBefore(dayEnd) && !r.end.isBefore(dayStart);
  }

  //* True when the start has no time-of-day (00:00) → treated as "All day"
  bool get isAllDay {
    final s = eventWallClock(this);
    return s.hour == 0 && s.minute == 0;
  }

  //* True when start and end fall on different calendar days (venue tz)
  bool get isMultiDay {
    if (end == null) return false;
    final r = wallClockRange;
    return r.start.year != r.end.year ||
        r.start.month != r.end.month ||
        r.start.day != r.end.day;
  }
}

//* True when the venue's UTC offset differs from the phone's right now
bool venueTzDiffersFromPhone(String? tzName) {
  final loc = venueLocation(tzName);
  if (loc == tz.UTC && (tzName ?? '').isEmpty) return false;
  final now = DateTime.now().toUtc();
  final venueOffset = tz.TZDateTime.from(now, loc).timeZoneOffset;
  return venueOffset != DateTime.now().timeZoneOffset;
}

//* Localised "All day" string, passed in to keep this file UI-free
class DurationLabels {
  final String allDay;
  const DurationLabels({required this.allDay});
}

//* Start time as "HH:mm", or "All day" for midnight-start (date-only) events
String? eventDurationLabel(
  Event event, {
  required DurationLabels labels,
  String? locale,
}) {
  final wall = eventWallClock(event);
  if (wall.hour == 0 && wall.minute == 0) return labels.allDay;
  return formatEventTime(event, 'HH:mm', locale: locale);
}

//* Time label "as of today": start time on day one, "All day" on later days
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

//* Short venue tz label from the IANA name (e.g. 'Europe/Warsaw' → 'Warsaw')
String venueTzShortName(String? tzName) {
  final loc = venueLocation(tzName);
  if (loc == tz.UTC) return 'UTC';
  final parts = loc.name.split('/');
  return parts.last.replaceAll('_', ' ');
}
