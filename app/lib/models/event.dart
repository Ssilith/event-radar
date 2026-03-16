import 'dart:math';
import 'package:json_annotation/json_annotation.dart';

part 'event.g.dart';

@JsonSerializable()
class Event {
  final String id;
  final String title;
  final String city;

  final String? category;

  @JsonKey(fromJson: _parseDate)
  final DateTime start;
  @JsonKey(fromJson: _parseDateOrNull)
  final DateTime? end;

  final String? venue;
  final double? latitude;
  final double? longitude;

  final String? description;
  final String? url;
  final String? source;

  final String? price;

  @JsonKey(name: 'updated_at', fromJson: _parseDateOrNull)
  final DateTime? updatedAt;

  const Event({
    required this.id,
    required this.title,
    required this.city,
    this.category,
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
  });

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
  Map<String, dynamic> toJson() => _$EventToJson(this);

  bool get hasLocation => latitude != null && longitude != null;

  bool get isUpcoming => start.isAfter(DateTime.now());

  bool get isFree {
    final p = price?.trim().toLowerCase();
    if (p == null) return false;

    if (p.contains('free')) return true;

    final number = double.tryParse(
      p.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.'),
    );

    return number == 0;
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
  final dt = DateTime.tryParse(raw);
  if (dt != null) return dt.toLocal();

  final stripped = raw.replaceFirst(RegExp(r'[+-]\d{2}:\d{2}$'), '');
  return DateTime.tryParse(stripped)?.toLocal() ??
      (throw FormatException('Cannot parse date: $raw'));
}

DateTime? _parseDateOrNull(String? raw) => raw == null ? null : _parseDate(raw);
