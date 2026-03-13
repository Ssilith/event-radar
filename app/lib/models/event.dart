import 'dart:math';

class Event {
  final String id;
  final String title;
  final String city;
  final DateTime start;
  final DateTime? end;
  final String? venue;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String? url;
  final String? source;
  final String? price;
  final DateTime? updatedAt;

  const Event({
    required this.id,
    required this.title,
    required this.city,
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

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      city: json['city'] as String,
      start: DateTime.parse(json['start'] as String),
      end: json['end'] != null ? DateTime.parse(json['end'] as String) : null,
      venue: json['venue'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'] as String?,
      url: json['url'] as String?,
      source: json['source'] as String?,
      price: json['price'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  double? distanceTo(double lat, double lon) {
    if (latitude == null || longitude == null) return null;
    const r = 6371.0; // Earth radius in km
    final dLat = _rad(lat - latitude!);
    final dLon = _rad(lon - longitude!);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(latitude!)) * cos(_rad(lat)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;

  bool get hasLocation => latitude != null && longitude != null;
  bool get isFree =>
      price != null &&
      (price!.contains('0') || price!.toLowerCase().contains('free'));
  bool get isUpcoming => start.isAfter(DateTime.now());

  @override
  String toString() => 'Event($id, $title, $start)';
}
