import 'package:event_radar/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

enum EventCategory {
  music,
  theater,
  art,
  festival,
  food,
  sports,
  comedy,
  dance,
  literature,
  education,
  family,
  film,
  market,
  business,
  social,
  tour,
  other,
}

const Map<EventCategory, IconData> eventCategoryIcons = {
  EventCategory.music: Icons.music_note,
  EventCategory.theater: Icons.theater_comedy,
  EventCategory.art: Icons.palette,
  EventCategory.festival: Icons.festival,
  EventCategory.food: Icons.restaurant,
  EventCategory.sports: Icons.sports,
  EventCategory.comedy: Icons.sentiment_very_satisfied,
  EventCategory.dance: Icons.accessibility_new,
  EventCategory.literature: Icons.menu_book,
  EventCategory.education: Icons.school,
  EventCategory.family: Icons.child_care,
  EventCategory.film: Icons.movie,
  EventCategory.market: Icons.storefront,
  EventCategory.business: Icons.business,
  EventCategory.social: Icons.people,
  EventCategory.tour: Icons.tour,
  EventCategory.other: Icons.category,
};

Map<EventCategory, Color> eventCategoryColors = {
  EventCategory.music: Colors.pink.shade200,
  EventCategory.theater: Colors.blue.shade200,
  EventCategory.art: Colors.purple.shade200,
  EventCategory.festival: Colors.orange.shade200,
  EventCategory.food: Colors.green.shade200,
  EventCategory.sports: Colors.indigo.shade200,
  EventCategory.comedy: Colors.yellow.shade200,
  EventCategory.dance: Colors.teal.shade200,
  EventCategory.literature: Colors.brown.shade200,
  EventCategory.education: Colors.cyan.shade200,
  EventCategory.family: Colors.lime.shade200,
  EventCategory.film: Colors.grey.shade400,
  EventCategory.market: Colors.amber.shade200,
  EventCategory.business: Colors.blueGrey.shade200,
  EventCategory.social: Colors.deepPurple.shade200,
  EventCategory.tour: Colors.lightGreen.shade200,
  EventCategory.other: Colors.grey.shade400,
};

extension EventCategoryExt on EventCategory {
  String get value => name.capitalize();
  IconData get iconData => eventCategoryIcons[this]!;
  Color get color => eventCategoryColors[this]!;
}
