import 'dart:math';
import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/utils/html_text.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event.g.dart';

@JsonSerializable()
class Event {
  final String id;

  // Title keeps its raw HTML so display sites can render <b>/<i>/<u>/<br>
  // via HtmlText. Dedupe / sort code reads it case-insensitively so leftover
  // tag chars don't cause false splits.
  final String title;

  @JsonKey(fromJson: _cleanText)
  final String city;

  @JsonKey(fromJson: _parseEventCategory)
  final EventCategory category;

  @JsonKey(fromJson: _parseDate)
  final DateTime start;
  @JsonKey(fromJson: _parseDateOrNull)
  final DateTime? end;

  @JsonKey(fromJson: htmlToTextOrNull)
  final String? venue;
  final double? latitude;
  final double? longitude;

  // Description keeps its raw HTML so the details screen can render <b>/<i>/
  // <p>/<br>/<a> with flutter_html. Other text fields are pre-cleaned because
  // rich markup in them is rare and breaks line-wrapping in compact rows.
  final String? description;
  final String? url;
  final String? source;

  @JsonKey(fromJson: htmlToTextOrNull)
  final String? price;

  @JsonKey(name: 'updated_at', fromJson: _parseDateOrNull)
  final DateTime? updatedAt;

  // IANA timezone name of the venue, e.g. "Europe/Warsaw". Injected at parse
  // time from the dataset wrapper (not present on individual event payloads).
  // Resolved by the indexer from country_code via pytz, so Flutter has no
  // country→tz mapping to maintain.
  @JsonKey(defaultValue: '')
  final String timezone;

  const Event({
    required this.id,
    required this.title,
    required this.city,
    required this.category,
    required this.start,
    this.end,
    this.venue,
    this.latitude,
    this.longitude,
    this.description,
    this.url,
    this.source,
    this.price,
    this.updatedAt,
    this.timezone = '',
  });

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Map<String, dynamic> toJson() => _$EventToJson(this);

  bool get hasLocation =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite;

  bool get isUpcoming => start.isAfter(DateTime.now().toUtc());

  bool get hasPrice {
    final p = price?.trim();
    return p != null && p.isNotEmpty;
  }

  bool get isFree {
    final p = price?.trim().toLowerCase();
    if (p == null || p.isEmpty) return false;
    if (p.contains('free')) return true;
    final asNumber = double.tryParse(
      p.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.'),
    );
    return asNumber == 0;
  }

  double? distanceTo(double lat, double lon) {
    if (!hasLocation) return null;

    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat - latitude!);
    final dLon = _toRad(lon - longitude!);

    final sinHalfDLat = sin(dLat / 2);
    final sinHalfDLon = sin(dLon / 2);

    final a =
        sinHalfDLat * sinHalfDLat +
        cos(_toRad(latitude!)) * cos(_toRad(lat)) * sinHalfDLon * sinHalfDLon;

    return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}

double _toRad(double deg) => deg * pi / 180;

DateTime _parseDate(String raw) {
  // Indexer emits UTC. We keep it UTC here — formatting happens in the venue's
  // timezone via formatEventTime(), so .toLocal() (phone tz) is no longer used.
  var dt = DateTime.tryParse(raw);
  if (dt == null) throw FormatException('Cannot parse date: $raw');
  if (!dt.isUtc) {
    dt = DateTime.utc(
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond,
      dt.microsecond,
    );
  }
  return dt;
}

DateTime? _parseDateOrNull(String? raw) => raw == null ? null : _parseDate(raw);

// Non-nullable counterpart used for required text fields. The shared helper
// is in html_text.dart; this thin wrapper exists because json_serializable's
// fromJson hook for a non-nullable field must itself be non-nullable.
String _cleanText(String raw) => htmlToText(raw);

EventCategory _parseEventCategory(String? category) {
  final needle = category?.toLowerCase();
  return EventCategory.values.firstWhere(
    (s) => s.name.toLowerCase() == needle,
    orElse: () => EventCategory.other,
  );
}
