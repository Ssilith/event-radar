import 'package:event_radar/l10n/generated/app_localizations.dart';

enum EventSort { date, nearby }

extension EventSortExt on EventSort {
  String label(AppL10n l) => switch (this) {
        EventSort.date => l.sortByDate,
        EventSort.nearby => l.sortByNearby,
      };
}
