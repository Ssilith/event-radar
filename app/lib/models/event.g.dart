// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
  id: json['id'] as String,
  title: json['title'] as String,
  city: json['city'] as String,
  category: _parseEventCategory(json['category'] as String?),
  start: _parseDate(json['start'] as String),
  end: _parseDateOrNull(json['end'] as String?),
  venue: json['venue'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  description: json['description'] as String?,
  url: json['url'] as String?,
  source: json['source'] as String?,
  price: json['price'] as String?,
  updatedAt: _parseDateOrNull(json['updated_at'] as String?),
);

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'city': instance.city,
  'category': _$EventCategoryEnumMap[instance.category]!,
  'start': instance.start.toIso8601String(),
  'end': instance.end?.toIso8601String(),
  'venue': instance.venue,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'description': instance.description,
  'url': instance.url,
  'source': instance.source,
  'price': instance.price,
  'updated_at': instance.updatedAt?.toIso8601String(),
};

const _$EventCategoryEnumMap = {
  EventCategory.music: 'music',
  EventCategory.theater: 'theater',
  EventCategory.art: 'art',
  EventCategory.festival: 'festival',
  EventCategory.food: 'food',
  EventCategory.sports: 'sports',
  EventCategory.comedy: 'comedy',
  EventCategory.dance: 'dance',
  EventCategory.literature: 'literature',
  EventCategory.education: 'education',
  EventCategory.family: 'family',
  EventCategory.film: 'film',
  EventCategory.market: 'market',
  EventCategory.business: 'business',
  EventCategory.social: 'social',
  EventCategory.tour: 'tour',
  EventCategory.other: 'other',
};
