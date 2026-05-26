import 'package:event_radar/l10n/generated/app_localizations.dart';
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

const Map<EventCategory, IconData> _eventCategoryIcons = {
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

Map<EventCategory, Color> _eventCategoryColors = {
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
  IconData get iconData => _eventCategoryIcons[this]!;
  Color get color => _eventCategoryColors[this]!;

  // Localized display label. Falls back to the enum name in title case if a
  // future category is added and the ARB hasn't caught up yet.
  String label(AppL10n l) => switch (this) {
        EventCategory.music => l.categoryMusic,
        EventCategory.theater => l.categoryTheater,
        EventCategory.art => l.categoryArt,
        EventCategory.festival => l.categoryFestival,
        EventCategory.food => l.categoryFood,
        EventCategory.sports => l.categorySports,
        EventCategory.comedy => l.categoryComedy,
        EventCategory.dance => l.categoryDance,
        EventCategory.literature => l.categoryLiterature,
        EventCategory.education => l.categoryEducation,
        EventCategory.family => l.categoryFamily,
        EventCategory.film => l.categoryFilm,
        EventCategory.market => l.categoryMarket,
        EventCategory.business => l.categoryBusiness,
        EventCategory.social => l.categorySocial,
        EventCategory.tour => l.categoryTour,
        EventCategory.other => l.categoryOther,
      };
}
