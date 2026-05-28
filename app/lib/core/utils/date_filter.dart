import 'package:event_radar/l10n/generated/app_localizations.dart';

enum DateFilter { today, week, month, all, past }

extension DateFilterExt on DateFilter {
  String label(AppL10n l) => switch (this) {
        DateFilter.today => l.filterToday,
        DateFilter.week => l.filterWeek,
        DateFilter.month => l.filterMonth,
        DateFilter.all => l.filterAll,
        DateFilter.past => l.filterPast,
      };
}
