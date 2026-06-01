import 'dart:async';

import 'package:event_radar/core/models/city_data_state.dart';
import 'package:event_radar/core/models/city_item.dart';
import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/services/bookmark_actions.dart';
import 'package:event_radar/core/services/city_service.dart';
import 'package:event_radar/core/services/event_cache_service.dart';
import 'package:event_radar/core/services/event_service.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:diacritic/diacritic.dart';
import 'package:event_radar/core/utils/date_filter.dart';
import 'package:event_radar/core/utils/event_dedup.dart';
import 'package:event_radar/core/utils/event_sort.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/core/utils/language.dart';
import 'package:event_radar/features/discover/widgets/category_bar.dart';
import 'package:event_radar/features/discover/widgets/city_picker_page.dart';
import 'package:event_radar/features/discover/widgets/date_filter_bar.dart';
import 'package:event_radar/features/discover/widgets/discover_empty_state.dart';
import 'package:event_radar/features/discover/widgets/discover_header.dart';
import 'package:event_radar/features/discover/widgets/discover_search_field.dart';
import 'package:event_radar/features/discover/widgets/event_row.dart';
import 'package:event_radar/features/discover/widgets/featured_carousel.dart';
import 'package:event_radar/features/discover/widgets/section_header.dart';
import 'package:event_radar/features/discover/widgets/sort_bar.dart';
import 'package:event_radar/features/event_details/event_details_screen.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/async_state_view.dart';
import 'package:event_radar/widgets/status_view.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class DiscoverScreen extends StatefulWidget {
  final CityItem? selectedCity;
  final ValueChanged<CityItem> onCitySelected;
  const DiscoverScreen({
    super.key,
    required this.selectedCity,
    required this.onCitySelected,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _cityService = CityService.instance;
  final _eventService = EventService.instance;

  bool _cityLoading = true;
  StreamSubscription<CityDataState>? _sub;
  CityDataState _state = const CityDataState.triggered();

  DateFilter _dateFilter = DateFilter.all;
  EventCategory? _selectedCategory;
  EventSort _sort = EventSort.date;
  bool _freeOnly = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  Set<String> _bookmarked = {};
  StreamSubscription<BoxEvent>? _bookmarkSub;

  @override
  void initState() {
    super.initState();
    _bookmarked = EventCacheService.bookmarkedIds();
    _bookmarkSub = EventCacheService.watchBookmarks()?.listen((_) {
      if (!mounted) return;
      setState(() => _bookmarked = EventCacheService.bookmarkedIds());
    });
    // EventRow reads SettingsService.distanceUnit statically, so when the
    // user flips the unit from the bottom sheet we need a parent rebuild to
    // re-render the pill text.
    SettingsService.instance.distanceUnit.addListener(_onSettingsChanged);
    _initCity();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant DiscoverScreen old) {
    super.didUpdateWidget(old);
    if (old.selectedCity != widget.selectedCity) _loadEvents();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _bookmarkSub?.cancel();
    _searchController.dispose();
    SettingsService.instance.distanceUnit.removeListener(_onSettingsChanged);
    super.dispose();
  }

  Future<void> _initCity() async {
    await _cityService.init();
    if (!mounted) return;
    setState(() => _cityLoading = false);

    final resolved = await _cityService.resolveLocation(
      languageCode: deviceLanguageCode,
    );
    if (!mounted) return;

    if (resolved && widget.selectedCity == null) {
      final city = _cityService.locationCity;
      if (city != null) {
        _cityService.markUsed(city);
        widget.onCitySelected(city);
        return;
      }
    }

    setState(() {});
    if (widget.selectedCity != null) _loadEvents();
  }

  Future<void> _loadEvents() {
    final city = widget.selectedCity;
    if (city == null) return Future.value();
    _sub?.cancel();
    setState(() {
      _state = const CityDataState.triggered();
      _selectedCategory = null;
    });
    final slug = EventService.slugFor(city);
    // Resolved when the stream emits a terminal status — gives callers like
    // RefreshIndicator a Future to await that mirrors the round trip.
    final done = Completer<void>();
    _sub = _eventService
        .getEventsForCity(
          slug,
          countryCode: city.countryCode,
          includePast: true,
        )
        .listen(
          (s) {
            setState(() => _state = s);
            if (_isTerminal(s.status) && !done.isCompleted) done.complete();
          },
          onError: (_) {
            setState(() => _state = const CityDataState.error());
            if (!done.isCompleted) done.complete();
          },
          onDone: () {
            if (!done.isCompleted) done.complete();
          },
        );
    return done.future;
  }

  Future<void> _refresh() {
    final city = widget.selectedCity;
    if (city == null) return Future.value();
    // Drop the in-memory cache so the next subscription hits the network
    // instead of replaying the still-fresh cached copy.
    _eventService.invalidateCache(EventService.slugFor(city));
    return _loadEvents();
  }

  static bool _isTerminal(CityDataStatus status) =>
      status == CityDataStatus.fresh ||
      status == CityDataStatus.ready ||
      status == CityDataStatus.error ||
      status == CityDataStatus.timeout;

  Future<void> _toggleBookmark(Event event) =>
      BookmarkActions.toggle(event, AppL10n.of(context));

  void _openCityPicker() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CityPickerPage(
          initialValue: widget.selectedCity,
          onCitySelected: (city) {
            Navigator.of(context).pop();
            _cityService.markUsed(city);
            widget.onCitySelected(city);
          },
        ),
      ),
    );
  }

  void _openDetails(Event event) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
    );
  }

  List<EventCategory> get _availableCategories =>
      _state.events.map((e) => e.category).toSet().toList();

  List<Event> get _dateFiltered =>
      _state.events.where(_dateFilter.matches).toList();

  List<Event> get _filtered {
    var events = _selectedCategory == null
        ? _dateFiltered
        : _dateFiltered.where((e) => e.category == _selectedCategory).toList();
    if (_freeOnly) {
      events = events.where((e) => e.isFree).toList();
    }
    final q = removeDiacritics(_searchQuery.trim().toLowerCase());
    if (q.isNotEmpty) {
      // Match against title + venue, diacritic-folded so "wroclaw" finds
      // "Wrocław". Title may still carry HTML tags from the raw feed; strip
      // them for the search index but not for display.
      events = events.where((e) {
        final hay = removeDiacritics(
          '${e.title} ${e.venue ?? ''}'.toLowerCase(),
        );
        return hay.contains(q);
      }).toList();
    }
    // Collapse the same occurrence re-listed as overlapping date ranges before
    // sorting, so an event can't appear two or three times in the feed.
    return _applySort(dedupeOverlapping(events));
  }

  // Sorts the post-filter list. Date sort uses venue wall-clock so all-day
  // entries lead their day. Nearby sort falls back to date when the user has
  // no location fix, or for events without coordinates (pushed to the end).
  List<Event> _applySort(List<Event> events) {
    if (_sort == EventSort.nearby && _nearbySortAvailable) {
      final pos = _cityService.lastPosition!;
      final ranked =
          events
              .map((e) => (e, e.distanceTo(pos.latitude, pos.longitude)))
              .toList()
            ..sort((a, b) {
              final da = a.$2;
              final db = b.$2;
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return da.compareTo(db);
            });
      return ranked.map((r) => r.$1).toList();
    }
    return [...events]
      ..sort((a, b) => eventWallClock(a).compareTo(eventWallClock(b)));
  }

  bool get _nearbySortAvailable => _cityService.lastPosition != null;

  List<Event> get _featuredEvents {
    final seen = <String>{};
    // Today-only, sorted chronologically by venue wall-clock so all-day
    // entries (parsed to 00:00) lead and timed events follow in hour order.
    // _state.events isn't reliably chronological (it may be sorted by distance
    // from the user when location is known), so sort here explicitly.
    final todays = _state.events.where((e) => e.isHappeningToday).toList()
      ..sort((a, b) => eventWallClock(a).compareTo(eventWallClock(b)));
    final result = <Event>[];
    for (final e in todays) {
      final key = '${e.title.toLowerCase()}|${(e.venue ?? '').toLowerCase()}';
      if (seen.add(key)) result.add(e);
      if (result.length >= 5) break;
    }
    return result;
  }

  bool get _hasData =>
      _state.status == CityDataStatus.fresh ||
      _state.status == CityDataStatus.ready;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: widget.selectedCity == null
          ? _buildEmptyState(context)
          : _buildEventFeed(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          DiscoverHeader(
            city: widget.selectedCity,
            compact: false,
            onTapCity: _openCityPicker,
          ),
          Expanded(
            child: DiscoverEmptyState(
              cityLoading: _cityLoading,
              onPickCity: _openCityPicker,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventFeed(BuildContext context) {
    final l = AppL10n.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        // Always allow overscroll so pull-to-refresh works when the list is short.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: DiscoverHeader(
              city: widget.selectedCity,
              compact: true,
              onTapCity: _openCityPicker,
            ),
          ),
          // SliverToBoxAdapter(
          //   child: DiscoverStatsCard(
          //     isPolling: _isPolling,
          //     eventCount: _state.events.length,
          //   ),
          // ),
          if (_hasData) ...[
            if (_featuredEvents.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: l.featuredSection,
                  trailing: DateFormat(
                    'EEEE',
                    Localizations.localeOf(context).languageCode,
                  ).format(DateTime.now()),
                ),
              ),
              SliverToBoxAdapter(
                child: FeaturedCarousel(
                  events: _featuredEvents,
                  bookmarked: _bookmarked,
                  onToggleBookmark: _toggleBookmark,
                  onOpenDetails: _openDetails,
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SectionHeader(
                title: l.allEventsSection,
                trailing: l.eventsFound(_filtered.length),
              ),
            ),
            SliverToBoxAdapter(
              child: DiscoverSearchField(
                controller: _searchController,
                query: _searchQuery,
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            ),
            SliverToBoxAdapter(
              child: DateFilterBar(
                filter: _dateFilter,
                freeOnly: _freeOnly,
                onFilterChanged: (f) => setState(() => _dateFilter = f),
                onFreeOnlyChanged: (v) => setState(() => _freeOnly = v),
              ),
            ),
            SliverToBoxAdapter(
              child: CategoryBar(
                selected: _selectedCategory,
                available: _availableCategories,
                onChanged: (c) => setState(() => _selectedCategory = c),
              ),
            ),
            SliverToBoxAdapter(
              child: SortBar(
                sort: _sort,
                nearbyAvailable: _nearbySortAvailable,
                onChanged: (s) => setState(() => _sort = s),
              ),
            ),
            if (_filtered.isEmpty)
              const SliverToBoxAdapter(child: StatusView.empty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => EventRow(
                    event: _filtered[i],
                    isSaved: _bookmarked.contains(_filtered[i].id),
                    onToggleSave: () => _toggleBookmark(_filtered[i]),
                    onOpen: () => _openDetails(_filtered[i]),
                    userPosition: _cityService.lastPosition,
                  ),
                  childCount: _filtered.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ] else
            SliverFillRemaining(
              child: AsyncStateView(
                state: _state,
                onRetry: _loadEvents,
                dataBuilder: (_) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
