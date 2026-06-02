import 'package:event_radar/l10n/generated/app_localizations.dart';

//* Sort order for the events feed
enum EventSort { date, nearby }

extension EventSortExt on EventSort {
  //* Localized sort label
  String label(AppL10n l) => switch (this) {
        EventSort.date => l.sortByDate,
        EventSort.nearby => l.sortByNearby,
      };
}
