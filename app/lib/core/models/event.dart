import 'dart:math';
import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/utils/html_parsing.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event.g.dart';

//* A single event, parsed from a city dataset
@JsonSerializable()
class Event {
  final String id;
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

  final String? description;
  final String? url;
  final String? source;

  @JsonKey(fromJson: htmlToTextOrNull)
  final String? price;

  @JsonKey(name: 'updated_at', fromJson: _parseDateOrNull)
  final DateTime? updatedAt;

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

  //* True when the event has usable (finite) coordinates
  bool get hasLocation =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite;

  //* True when a non-empty price string is present
  bool get hasPrice {
    final p = price?.trim();
    return p != null && p.isNotEmpty;
  }

  //* True when the price reads as free or parses to zero
  bool get isFree {
    final p = price?.trim().toLowerCase();
    if (p == null || p.isEmpty) return false;
    if (p.contains('free')) return true;
    final asNumber = double.tryParse(
      p.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.'),
    );
    return asNumber == 0;
  }

  //* Haversine great-circle distance in km to a point (null without coords)
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

//* Degrees → radians
double _toRad(double deg) => deg * pi / 180;

//* Parse an ISO date, normalizing naive timestamps to UTC
DateTime _parseDate(String raw) {
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

//* Nullable variant of _parseDate
DateTime? _parseDateOrNull(String? raw) => raw == null ? null : _parseDate(raw);

//* Strip HTML from a required text field
String _cleanText(String raw) => htmlToText(raw);

//* Map a raw category string to an EventCategory (other when unknown)
EventCategory _parseEventCategory(String? category) {
  final needle = category?.toLowerCase();
  return EventCategory.values.firstWhere(
    (s) => s.name.toLowerCase() == needle,
    orElse: () => EventCategory.other,
  );
}
