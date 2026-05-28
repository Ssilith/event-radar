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
import 'package:event_radar/core/theme/app_shadows.dart';
import 'package:diacritic/diacritic.dart';
import 'package:event_radar/core/utils/date_filter.dart';
import 'package:event_radar/core/utils/event_sort.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/core/utils/language.dart';
import 'package:event_radar/features/discover/widgets/city_picker_page.dart';
import 'package:event_radar/features/discover/widgets/event_row.dart';
import 'package:event_radar/features/discover/widgets/featured_carousel.dart';
import 'package:event_radar/features/discover/widgets/icon_btn.dart';
import 'package:event_radar/features/discover/widgets/section_header.dart';
import 'package:event_radar/features/discover/widgets/settings_sheet.dart';
import 'package:event_radar/features/event_details/event_details_screen.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/async_state_view.dart';
import 'package:event_radar/widgets/status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
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
        .getEventsForCity(slug, countryCode: city.countryCode)
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

  List<Event> get _dateFiltered {
    return _state.events.where((e) {
      final start = eventWallClock(e);
      final now = nowInVenueTz(e.timezone);
      return switch (_dateFilter) {
        DateFilter.today => DateUtils.isSameDay(start, now),
        DateFilter.week =>
          start.isAfter(now) && start.isBefore(now.add(const Duration(days: 7))),
        DateFilter.month =>
          start.isAfter(now) && start.isBefore(now.add(const Duration(days: 30))),
        DateFilter.all => true,
        DateFilter.past => start.isBefore(now),
      };
    }).toList();
  }

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
    return _applySort(events);
  }

  // Sorts the post-filter list. Date sort uses venue wall-clock so all-day
  // entries lead their day. Nearby sort falls back to date when the user has
  // no location fix, or for events without coordinates (pushed to the end).
  List<Event> _applySort(List<Event> events) {
    if (_sort == EventSort.nearby && _nearbySortAvailable) {
      final pos = _cityService.lastPosition!;
      final ranked = events
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
    final todays = _state.events.where(isEventToday).toList()
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

  bool get _isPolling =>
      _state.status == CityDataStatus.triggered ||
      _state.status == CityDataStatus.polling;

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
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context, compact: false),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_city_outlined,
                    size: 56,
                    color: primary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l.chooseCityToDiscoverEvents,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.syne(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_cityLoading)
                    SpinKitRipple(color: primary, size: 36)
                  else
                    FilledButton.icon(
                      onPressed: _openCityPicker,
                      icon: const Icon(Icons.search, size: 18),
                      label: Text(l.pickACity),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                ],
              ),
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
        SliverToBoxAdapter(child: _buildHeader(context, compact: true)),
        SliverToBoxAdapter(child: _buildStatsCard(context)),
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
          SliverToBoxAdapter(child: _buildSearchField(context)),
          SliverToBoxAdapter(child: _buildDateFilter(context)),
          SliverToBoxAdapter(child: _buildCategoryBar(context)),
          SliverToBoxAdapter(child: _buildSortBar(context)),
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

  Widget _buildHeader(BuildContext context, {required bool compact}) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    final city = widget.selectedCity;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          compact ? 12 : 20,
          8,
          compact ? 8 : 20,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _openCityPicker,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.discoveringEventsIn,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            city?.name ?? l.chooseCity,
                            style: GoogleFonts.syne(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: primary,
                          size: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconBtn(
              icon: Icons.tune_rounded,
              onTap: () => SettingsSheet.show(context),
              tooltip: l.settingsTitle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    final count = _state.events.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.22)),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 15, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: _isPolling
                ? Text(
                    l.discoveringEventsLoading,
                    style: TextStyle(fontSize: 13, color: primary),
                  )
                : RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: l.eventsAutoDiscoveredFrom(count),
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: l.schemaOrg,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (_isPolling)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: primary),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final l = AppL10n.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textInputAction: TextInputAction.search,
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: l.searchHint,
          hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
          prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textHint),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
          filled: true,
          fillColor: AppColors.surfaceHigh,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderStrong),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Row(
        children: [
          ...DateFilter.values.map((f) {
            final sel = _dateFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _dateFilter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: sel ? primary : AppColors.borderStrong,
                    ),
                    boxShadow: sel ? AppShadows.subtle : null,
                  ),
                  child: Text(
                    f.label(l),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? Colors.black : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            );
          }),
          // Separator + Free-only toggle. Lives in the same scroll row so
          // mobile users don't get another vertical band of chips.
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: AppColors.borderStrong,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(
              onTap: () => setState(() => _freeOnly = !_freeOnly),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _freeOnly ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _freeOnly ? primary : AppColors.borderStrong,
                  ),
                  boxShadow: _freeOnly ? AppShadows.subtle : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.savings_rounded,
                      size: 14,
                      color: _freeOnly ? Colors.black : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.filterFreeOnly,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            _freeOnly ? FontWeight.w700 : FontWeight.w400,
                        color:
                            _freeOnly ? Colors.black : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar(BuildContext context) {
    final l = AppL10n.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    // Nearby chip is shown but disabled when the user's GPS fix isn't known —
    // makes the option discoverable so the user knows enabling location will
    // unlock it, instead of hiding the chip silently.
    final available = _nearbySortAvailable;
    // Segmented-control style — single rounded shell with one filled segment
    // at a time. Reads as "which lens am I looking through" instead of two
    // independent toggles.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Icon(Icons.sort_rounded, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            l.sortByLabel,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfacePill),
            ),
            child: Row(
              children: EventSort.values.map((s) {
                final enabled = s == EventSort.date || available;
                final selected = _sort == s;
                final icon = s == EventSort.date
                    ? Icons.event_rounded
                    : Icons.near_me_rounded;
                return GestureDetector(
                  onTap: enabled ? () => setState(() => _sort = s) : null,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: selected ? AppShadows.subtle : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 13,
                          color: selected
                              ? Colors.black
                              : enabled
                                  ? AppColors.textBody
                                  : AppColors.textFaint,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          s.label(l),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? Colors.black
                                : enabled
                                    ? AppColors.textBody
                                    : AppColors.textFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [null, ..._availableCategories].map((cat) {
          final sel = _selectedCategory == cat;
          final color = cat?.color ?? scheme.primary;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                cat?.iconData ?? Icons.apps_rounded,
                size: 15,
                color: sel ? Colors.black : color,
              ),
              label: Text(cat?.label(l) ?? l.categoryAll),
              selected: sel,
              onSelected: (_) =>
                  setState(() => _selectedCategory = sel ? null : cat),
              showCheckmark: false,
              selectedColor: color,
              backgroundColor: AppColors.border,
              side: BorderSide(
                color: sel ? color : AppColors.borderStrong,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                color: sel ? Colors.black : AppColors.textBody,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
      ),
    );
  }
}
