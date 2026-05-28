import 'dart:async';

import 'package:event_radar/core/models/city_item.dart';
import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/services/city_service.dart';
import 'package:event_radar/core/services/event_cache_service.dart';
import 'package:event_radar/core/services/notification_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/features/saved/models/group.dart';
import 'package:event_radar/features/saved/models/group_mode.dart';
import 'package:event_radar/features/saved/widgets/empty_bookmarks.dart';
import 'package:event_radar/features/saved/widgets/group_section.dart';
import 'package:event_radar/features/saved/widgets/group_toggle.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SavedScreen extends StatefulWidget {
  final CityItem? currentCity;
  const SavedScreen({super.key, this.currentCity});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<Event> _saved = const [];
  StreamSubscription<BoxEvent>? _sub;
  GroupMode _groupMode = GroupMode.location;

  @override
  void initState() {
    super.initState();
    _refresh();
    _sub = EventCacheService.watchBookmarks()?.listen((_) => _refresh());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _saved = EventCacheService.getBookmarks());
  }

  Future<void> _remove(Event event) async {
    await EventCacheService.removeBookmark(event.id);
    await NotificationService.instance.cancelEventReminder(event.id);
  }

  List<Group> _groups(AppL10n l) => switch (_groupMode) {
        GroupMode.location => _groupByLocation(l),
        GroupMode.date => _groupByDate(l),
      };

  List<Group> _groupByLocation(AppL10n l) {
    final cityService = CityService.instance;
    final byDisplay = <String, List<Event>>{};
    final unknown = l.groupUnknown;
    for (final e in _saved) {
      final raw = e.city.trim();
      final display = raw.isEmpty ? unknown : cityService.displayCityName(raw);
      byDisplay.putIfAbsent(display, () => []).add(e);
    }
    final current = widget.currentCity?.name;

    final entries = byDisplay.entries.toList()
      ..sort((a, b) {
        final aCurrent = current != null && cityService.sameCity(a.key, current);
        final bCurrent = current != null && cityService.sameCity(b.key, current);
        if (aCurrent != bCurrent) return aCurrent ? -1 : 1;
        if (a.key == unknown) return 1;
        if (b.key == unknown) return -1;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    final nowUtc = DateTime.now().toUtc();
    return entries.map((e) {
      final isCurrent =
          current != null && cityService.sameCity(e.key, current);
      e.value.sort((x, y) {
        final xPast = x.start.isBefore(nowUtc);
        final yPast = y.start.isBefore(nowUtc);
        if (xPast != yPast) return xPast ? 1 : -1;
        if (xPast) return y.start.compareTo(x.start);
        return x.start.compareTo(y.start);
      });
      return Group(label: e.key, events: e.value, emphasis: isCurrent);
    }).toList();
  }

  // Internal bucket keys are stable enums so we can sort and emphasize without
  // string comparisons against translated labels.
  static const _bucketOrder = [
    _DateBucket.today,
    _DateBucket.tomorrow,
    _DateBucket.thisWeek,
    _DateBucket.thisMonth,
    _DateBucket.later,
    _DateBucket.past,
  ];

  List<Group> _groupByDate(AppL10n l) {
    final nowUtc = DateTime.now().toUtc();
    final buckets = {for (final b in _bucketOrder) b: <Event>[]};

    for (final e in _saved) {
      // Bucket by the event's own venue-local date, not the phone's date.
      final start = eventWallClock(e);
      final venueNow = nowInVenueTz(e.timezone);
      final today = DateUtils.dateOnly(venueNow);
      final tomorrow = today.add(const Duration(days: 1));
      final weekEnd = today.add(const Duration(days: 7));
      final monthEnd = today.add(const Duration(days: 30));

      if (start.isBefore(today)) {
        buckets[_DateBucket.past]!.add(e);
      } else if (DateUtils.isSameDay(start, venueNow)) {
        buckets[_DateBucket.today]!.add(e);
      } else if (DateUtils.isSameDay(start, tomorrow)) {
        buckets[_DateBucket.tomorrow]!.add(e);
      } else if (start.isBefore(weekEnd)) {
        buckets[_DateBucket.thisWeek]!.add(e);
      } else if (start.isBefore(monthEnd)) {
        buckets[_DateBucket.thisMonth]!.add(e);
      } else {
        buckets[_DateBucket.later]!.add(e);
      }
    }

    for (final entry in buckets.entries) {
      if (entry.key == _DateBucket.past) {
        entry.value.sort((a, b) => b.start.compareTo(a.start));
      } else if (entry.key == _DateBucket.today) {
        entry.value.sort((a, b) {
          final aPast = a.start.isBefore(nowUtc);
          final bPast = b.start.isBefore(nowUtc);
          if (aPast != bPast) return aPast ? 1 : -1;
          if (aPast) return b.start.compareTo(a.start);
          return a.start.compareTo(b.start);
        });
      } else {
        entry.value.sort((a, b) => a.start.compareTo(b.start));
      }
    }

    return buckets.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => Group(
              label: _bucketLabel(l, e.key),
              events: e.value,
              emphasis: e.key == _DateBucket.today,
            ))
        .toList();
  }

  String _bucketLabel(AppL10n l, _DateBucket b) => switch (b) {
        _DateBucket.today => l.bucketToday,
        _DateBucket.tomorrow => l.bucketTomorrow,
        _DateBucket.thisWeek => l.bucketThisWeek,
        _DateBucket.thisMonth => l.bucketThisMonth,
        _DateBucket.later => l.bucketLater,
        _DateBucket.past => l.bucketPast,
      };

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    final groups = _saved.isEmpty ? const <Group>[] : _groups(l);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.savedForLater,
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l.bookmarks,
                          style: GoogleFonts.syne(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l.savedCount(_saved.length),
                    style: TextStyle(color: primary, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (_saved.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: GroupToggle(
                  mode: _groupMode,
                  onChanged: (m) => setState(() => _groupMode = m),
                ),
              ),
            Expanded(
              child: _saved.isEmpty
                  ? const EmptyBookmarks()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: groups.length,
                      itemBuilder: (_, i) => GroupSection(
                        group: groups[i],
                        onRemove: _remove,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DateBucket { today, tomorrow, thisWeek, thisMonth, later, past }
