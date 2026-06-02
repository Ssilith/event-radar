import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

//* Event classification used for icons, colours, and filtering
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

//* Per-category icon
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

//* Per-category accent swatch; the shade is chosen per theme (see [color])
const Map<EventCategory, MaterialColor> _eventCategorySwatches = {
  EventCategory.music: Colors.pink,
  EventCategory.theater: Colors.blue,
  EventCategory.art: Colors.purple,
  EventCategory.festival: Colors.orange,
  EventCategory.food: Colors.green,
  EventCategory.sports: Colors.indigo,
  EventCategory.comedy: Colors.yellow,
  EventCategory.dance: Colors.teal,
  EventCategory.literature: Colors.brown,
  EventCategory.education: Colors.cyan,
  EventCategory.family: Colors.lime,
  EventCategory.film: Colors.grey,
  EventCategory.market: Colors.amber,
  EventCategory.business: Colors.blueGrey,
  EventCategory.social: Colors.deepPurple,
  EventCategory.tour: Colors.lightGreen,
  EventCategory.other: Colors.grey,
};

extension EventCategoryExt on EventCategory {
  //* This category's icon
  IconData get iconData => _eventCategoryIcons[this]!;
  //* This category's accent colour: pale pastel on dark surfaces, a deeper
  //* shade on light ones (the pastels wash out on a near-white background)
  Color get color {
    final swatch = _eventCategorySwatches[this]!;
    return AppColors.brightness == Brightness.dark
        ? swatch.shade200
        : swatch.shade700;
  }

  //* Localized category name
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
