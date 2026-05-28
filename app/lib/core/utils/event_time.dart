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

// True if `event.start` falls on the same calendar day as right-now in the
// venue's timezone. Used for the map's "today" emphasis.
bool isEventToday(Event event) {
  final start = eventWallClock(event);
  final now = nowInVenueTz(event.timezone);
  return start.year == now.year &&
      start.month == now.month &&
      start.day == now.day;
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

String venueTzShortName(String? tzName) {
  final loc = venueLocation(tzName);
  if (loc == tz.UTC) return 'UTC';
  // IANA zone last segment is usually the city — e.g. 'Europe/Warsaw' -> 'Warsaw'.
  final parts = loc.name.split('/');
  return parts.last.replaceAll('_', ' ');
}
