import 'dart:async';

import 'package:event_radar/models/city_item.dart';
import 'package:event_radar/models/event.dart';
import 'package:event_radar/models/event_category.dart';
import 'package:event_radar/screens/event_details_screen.dart';
import 'package:event_radar/services/city_service.dart';
import 'package:event_radar/services/event_cache_service.dart';
import 'package:event_radar/utils/event_time.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

enum _GroupMode { location, date }

class SavedScreen extends StatefulWidget {
  final CityItem? currentCity;
  const SavedScreen({super.key, this.currentCity});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<Event> _saved = const [];
  StreamSubscription<BoxEvent>? _sub;
  _GroupMode _groupMode = _GroupMode.location;

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
  }

  List<_Group> get _groups => switch (_groupMode) {
    _GroupMode.location => _groupByLocation(),
    _GroupMode.date => _groupByDate(),
  };

  List<_Group> _groupByLocation() {
    final cityService = CityService.instance;
    final byDisplay = <String, List<Event>>{};
    for (final e in _saved) {
      final raw = e.city.trim();
      final display = raw.isEmpty ? 'Unknown' : cityService.displayCityName(raw);
      byDisplay.putIfAbsent(display, () => []).add(e);
    }
    final current = widget.currentCity?.name;

    final entries = byDisplay.entries.toList()
      ..sort((a, b) {
        final aCurrent = current != null && cityService.sameCity(a.key, current);
        final bCurrent = current != null && cityService.sameCity(b.key, current);
        if (aCurrent != bCurrent) return aCurrent ? -1 : 1;
        if (a.key == 'Unknown') return 1;
        if (b.key == 'Unknown') return -1;
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
      return _Group(label: e.key, events: e.value, emphasis: isCurrent);
    }).toList();
  }

  List<_Group> _groupByDate() {
    final nowUtc = DateTime.now().toUtc();

    final buckets = <String, List<Event>>{
      'Today': [],
      'Tomorrow': [],
      'This week': [],
      'This month': [],
      'Later': [],
      'Past': [],
    };

    for (final e in _saved) {
      // Bucket by the event's own venue-local date, not the phone's date.
      final start = eventWallClock(e);
      final venueNow = nowInVenueTz(e.timezone);
      final today = DateUtils.dateOnly(venueNow);
      final tomorrow = today.add(const Duration(days: 1));
      final weekEnd = today.add(const Duration(days: 7));
      final monthEnd = today.add(const Duration(days: 30));

      if (start.isBefore(today)) {
        buckets['Past']!.add(e);
      } else if (DateUtils.isSameDay(start, venueNow)) {
        buckets['Today']!.add(e);
      } else if (DateUtils.isSameDay(start, tomorrow)) {
        buckets['Tomorrow']!.add(e);
      } else if (start.isBefore(weekEnd)) {
        buckets['This week']!.add(e);
      } else if (start.isBefore(monthEnd)) {
        buckets['This month']!.add(e);
      } else {
        buckets['Later']!.add(e);
      }
    }

    for (final entry in buckets.entries) {
      if (entry.key == 'Past') {
        entry.value.sort((a, b) => b.start.compareTo(a.start));
      } else if (entry.key == 'Today') {
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
        .map((e) => _Group(
              label: e.key,
              events: e.value,
              emphasis: e.key == 'Today',
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final groups = _saved.isEmpty ? const <_Group>[] : _groups;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
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
                          'SAVED FOR LATER',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Bookmarks',
                          style: GoogleFonts.syne(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_saved.length} saved',
                    style: TextStyle(color: primary, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (_saved.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: _GroupToggle(
                  mode: _groupMode,
                  onChanged: (m) => setState(() => _groupMode = m),
                ),
              ),
            Expanded(
              child: _saved.isEmpty
                  ? const _EmptyBookmarks()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: groups.length,
                      itemBuilder: (_, i) => _GroupSection(
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

class _Group {
  final String label;
  final List<Event> events;
  final bool emphasis;
  const _Group({
    required this.label,
    required this.events,
    required this.emphasis,
  });
}

class _GroupToggle extends StatelessWidget {
  final _GroupMode mode;
  final ValueChanged<_GroupMode> onChanged;
  const _GroupToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          _toggleButton(
            context,
            label: 'By location',
            icon: Icons.location_city_rounded,
            selected: mode == _GroupMode.location,
            primary: primary,
            onTap: () => onChanged(_GroupMode.location),
          ),
          _toggleButton(
            context,
            label: 'By date',
            icon: Icons.calendar_today_rounded,
            selected: mode == _GroupMode.date,
            primary: primary,
            onTap: () => onChanged(_GroupMode.date),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.black : const Color(0xFF999999),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.black : const Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  final _Group group;
  final Future<void> Function(Event) onRemove;
  const _GroupSection({required this.group, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              if (group.emphasis)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CURRENT',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  group.label,
                  style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: group.emphasis ? primary : Colors.white,
                  ),
                ),
              ),
              Text(
                '${group.events.length}',
                style: TextStyle(color: primary, fontSize: 12),
              ),
            ],
          ),
        ),
        ...group.events.map(
          (e) => _SavedEventRow(event: e, onRemove: () => onRemove(e)),
        ),
      ],
    );
  }
}

class _EmptyBookmarks extends StatelessWidget {
  const _EmptyBookmarks();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline_rounded,
              size: 56,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'No saved events yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the bookmark icon on an event\nin Discover to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888888), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedEventRow extends StatelessWidget {
  final Event event;
  final VoidCallback onRemove;
  const _SavedEventRow({required this.event, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isPast = event.start.isBefore(DateTime.now().toUtc());
    final eventLocal = eventWallClock(event);
    final catColor = EventCategory.values
        .firstWhere(
          (c) => c.value.toLowerCase() == event.category.value.toLowerCase(),
          orElse: () => EventCategory.other,
        )
        .color;

    return InkWell(
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF181818))),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: isPast
                    ? Colors.red.withValues(alpha: 0.09)
                    : primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isPast
                      ? Colors.red.withValues(alpha: 0.25)
                      : primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isPast
                        ? 'PAS'
                        : DateFormat('MMM').format(eventLocal).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isPast ? Colors.red.shade400 : primary,
                    ),
                  ),
                  Text(
                    '${eventLocal.day}',
                    style: GoogleFonts.syne(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  if (event.venue != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      event.venue!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.bookmark_rounded,
                    size: 19,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: catColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: Color(0xFF3A3A3A),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
