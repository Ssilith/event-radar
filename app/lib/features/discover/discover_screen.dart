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
import 'package:extension_utils/string_utils.dart';
import 'package:event_radar/core/utils/date_filter.dart';
import 'package:event_radar/core/utils/event_dedup.dart';
import 'package:event_radar/core/utils/event_sort.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/core/utils/language.dart';
import 'package:event_radar/features/discover/widgets/category_bar.dart';
import 'package:event_radar/features/discover/widgets/city_picker.dart';
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
import 'package:event_radar/widgets/app_toast.dart';
import 'package:event_radar/widgets/async_state_view.dart';
import 'package:event_radar/widgets/status_view.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

//* Discover tab: featured carousel + filterable, sortable events feed
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

  final _scrollController = ScrollController();
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    _bookmarked = EventCacheService.bookmarkedIds();
    _bookmarkSub = EventCacheService.watchBookmarks()?.listen((_) {
      if (!mounted) return;
      setState(() => _bookmarked = EventCacheService.bookmarkedIds());
    });
    //* Rebuild so distance pills refresh when the unit changes
    SettingsService.instance.distanceUnit.addListener(_onSettingsChanged);
    _scrollController.addListener(_onScroll);
    _initCity();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  //* Show the jump-to-top button
  void _onScroll() {
    final show = _scrollController.offset > 500;
    if (show != _showScrollTop) setState(() => _showScrollTop = show);
  }

  //* Animate the feed back to the top
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
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
    _scrollController.dispose();
    SettingsService.instance.distanceUnit.removeListener(_onSettingsChanged);
    super.dispose();
  }

  //* Init city service, then auto-select the GPS city when none is chosen
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

  //* Subscribe to the city's event stream; future completes on a terminal state
  Future<void> _loadEvents() {
    final city = widget.selectedCity;
    if (city == null) return Future.value();
    _sub?.cancel();
    setState(() {
      _state = const CityDataState.triggered();
      _selectedCategory = null;
    });
    final slug = EventService.slugFor(city);
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

  //* Pull-to-refresh: drop the cache and re-fetch from the network
  Future<void> _refresh() {
    final city = widget.selectedCity;
    if (city == null) return Future.value();
    _eventService.invalidateCache(EventService.slugFor(city));
    return _loadEvents();
  }

  //* Terminal stream states that complete the load future
  static bool _isTerminal(CityDataStatus status) =>
      status == CityDataStatus.fresh ||
      status == CityDataStatus.ready ||
      status == CityDataStatus.error ||
      status == CityDataStatus.timeout;

  //* Save/unsave an event (and schedule/cancel its reminder), confirming the
  //* reminder with a snackbar when one was set
  Future<void> _toggleBookmark(Event event) async {
    final l = AppL10n.of(context);
    final result = await BookmarkActions.toggle(event, l);
    if (!mounted || result.reminderAt == null) return;
    final when = formatReminderDate(
      result.reminderAt!,
      Localizations.localeOf(context).toLanguageTag(),
    );
    AppToast.reminder(context, title: l.reminderSetTitle, message: when);
  }

  //* Open the city chooser bottom sheet (markUsed is handled inside the sheet)
  void _openCityPicker() {
    CityPickerSheet.show(
      context,
      initialValue: widget.selectedCity,
      onCitySelected: widget.onCitySelected,
    );
  }

  //* Push the event details screen
  void _openDetails(Event event) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
    );
  }

  //* Categories present in the current dataset (for the chip bar)
  List<EventCategory> get _availableCategories =>
      _state.events.map((e) => e.category).toSet().toList();

  //* Events matching the active date filter
  List<Event> get _dateFiltered =>
      _state.events.where(_dateFilter.matches).toList();

  //* Full pipeline: date + category + free + search, deduped, then sorted
  List<Event> get _filtered {
    var events = _selectedCategory == null
        ? _dateFiltered
        : _dateFiltered.where((e) => e.category == _selectedCategory).toList();
    if (_freeOnly) {
      events = events.where((e) => e.isFree).toList();
    }
    final q = removeDiacritics(_searchQuery.trim().toLowerCase());
    if (q.isNotEmpty) {
      //* Diacritic-folded match on title + venue (so "wroclaw" finds "Wrocław")
      events = events.where((e) {
        final hay = removeDiacritics(
          '${e.title} ${e.venue ?? ''}'.toLowerCase(),
        );
        return hay.contains(q);
      }).toList();
    }
    //* Dedupe re-listed overlapping copies before sorting
    return _applySort(dedupeOverlapping(events));
  }

  //* Sort by nearby (when a fix is known) else by venue wall-clock date
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

  //* Up to 5 de-duplicated today events for the featured carousel
  List<Event> get _featuredEvents {
    final seen = <String>{};
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

  //* Whether a dataset is loaded and ready to render
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

  //* Header + "pick a city" prompt when no city is selected
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

  //* The scrollable feed: header, stats, featured carousel, filters, list
  Widget _buildEventFeed(BuildContext context) {
    final l = AppL10n.of(context);
    final filtered = _filtered;
    final featured = _featuredEvents;
    final feed = RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: DiscoverHeader(
              city: widget.selectedCity,
              compact: true,
              onTapCity: _openCityPicker,
            ),
          ),
          if (_hasData) ...[
            if (featured.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: l.featuredSection,
                  trailing: DateFormat(
                    'EEEE',
                    Localizations.localeOf(context).languageCode,
                  ).format(DateTime.now()).capitalize(),
                ),
              ),
              SliverToBoxAdapter(
                child: FeaturedCarousel(
                  events: featured,
                  bookmarked: _bookmarked,
                  onToggleBookmark: _toggleBookmark,
                  onOpenDetails: _openDetails,
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SectionHeader(
                title: l.allEventsSection,
                trailing: l.eventsFound(filtered.length),
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
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: StatusView.empty(
                  message: _dateFilter == DateFilter.past
                      ? l.statusEmptyPast
                      : null,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final e = filtered[i];
                  return EventRow(
                    event: e,
                    isSaved: _bookmarked.contains(e.id),
                    onToggleSave: () => _toggleBookmark(e),
                    onOpen: () => _openDetails(e),
                    userPosition: _cityService.lastPosition,
                  );
                }, childCount: filtered.length),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ] else
            SliverFillRemaining(
              child: AsyncStateView(state: _state, onRetry: _loadEvents),
            ),
        ],
      ),
    );
    return Stack(
      children: [
        feed,
        //* Floating jump-to-top button, shown once the feed is scrolled
        Positioned(
          right: 16,
          bottom: 16,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            offset: _showScrollTop ? Offset.zero : const Offset(0, 1.4),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showScrollTop ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_showScrollTop,
                child: _ScrollTopButton(onTap: _scrollToTop),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

//* Round button that animates the Discover feed back to the top
class _ScrollTopButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScrollTopButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.keyboard_arrow_up_rounded,
            color: AppColors.onPrimary,
            size: 26,
          ),
        ),
      ),
    );
  }
}
