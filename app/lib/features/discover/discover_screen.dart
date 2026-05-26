import 'dart:async';

import 'package:event_radar/core/models/city_data_state.dart';
import 'package:event_radar/core/models/city_item.dart';
import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/services/city_service.dart';
import 'package:event_radar/core/services/event_cache_service.dart';
import 'package:event_radar/core/services/event_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/utils/date_filter.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/core/utils/language.dart';
import 'package:event_radar/features/discover/widgets/city_picker_page.dart';
import 'package:event_radar/features/discover/widgets/event_row.dart';
import 'package:event_radar/features/discover/widgets/featured_carousel.dart';
import 'package:event_radar/features/discover/widgets/icon_btn.dart';
import 'package:event_radar/features/discover/widgets/section_header.dart';
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
    _initCity();
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

  void _loadEvents() {
    final city = widget.selectedCity;
    if (city == null) return;
    _sub?.cancel();
    setState(() {
      _state = const CityDataState.triggered();
      _selectedCategory = null;
    });
    final slug = EventService.slugFor(city);
    _sub = _eventService
        .getEventsForCity(slug, countryCode: city.countryCode)
        .listen(
          (s) => setState(() => _state = s),
          onError: (_) => setState(() => _state = const CityDataState.error()),
        );
  }

  Future<void> _toggleBookmark(Event event) =>
      EventCacheService.toggleBookmark(event);

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
      };
    }).toList();
  }

  List<Event> get _filtered {
    if (_selectedCategory == null) return _dateFiltered;
    return _dateFiltered.where((e) => e.category == _selectedCategory).toList();
  }

  List<Event> get _featuredEvents {
    final seen = <String>{};
    final result = <Event>[];

    // _filtered is already sorted by date, so first occurrence = soonest.
    for (final e in _filtered) {
      final start = eventWallClock(e);
      final today = DateUtils.dateOnly(nowInVenueTz(e.timezone));
      if (start.isBefore(today)) continue;
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, compact: true)),
        SliverToBoxAdapter(child: _buildStatsCard(context)),
        if (_hasData) ...[
          SliverToBoxAdapter(child: _buildDateFilter(context)),
          SliverToBoxAdapter(child: _buildCategoryBar(context)),
          if (_filtered.isNotEmpty) ...[
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
                events: _featuredEvents.take(5).toList(),
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
              icon: Icons.language_outlined,
              onTap: () {},
              tooltip: l.regionTooltip,
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
                      style: const TextStyle(
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
                          style: const TextStyle(
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

  Widget _buildDateFilter(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Row(
        children: DateFilter.values.map((f) {
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
        }).toList(),
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
