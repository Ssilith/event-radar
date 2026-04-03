enum DateFilter { today, week, month, all }

const Map<DateFilter, String> _dateFilterNames = {
  DateFilter.today: 'Today',
  DateFilter.week: 'This Week',
  DateFilter.month: 'This Month',
  DateFilter.all: 'All',
};

extension DateFilterExt on DateFilter {
  String get value => _dateFilterNames[this]!;
}
