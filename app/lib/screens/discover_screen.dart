import 'dart:async';

import 'package:diacritic/diacritic.dart';
import 'package:event_radar/models/city_data_state.dart';
import 'package:event_radar/models/city_item.dart';
import 'package:event_radar/models/event.dart';
import 'package:event_radar/models/event_category.dart';
import 'package:event_radar/services/city_service.dart';
import 'package:event_radar/services/event_cache_service.dart';
import 'package:event_radar/services/event_service.dart';
import 'package:event_radar/utils/date_filter.dart';
import 'package:event_radar/utils/language.dart';
import 'package:event_radar/widgets/city_picker.dart';
import 'package:event_radar/widgets/status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _initCity();
  }

  @override
  void didUpdateWidget(covariant DiscoverScreen old) {
    super.didUpdateWidget(old);
    if (old.selectedCity != widget.selectedCity) _loadEvents();
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
    final slug = removeDiacritics(city.name).toLowerCase().replaceAll(' ', '-');
    _sub = _eventService
        .getEventsForCity(slug, countryCode: city.countryCode)
        .listen(
          (s) => setState(() => _state = s),
          onError: (_) => setState(() => _state = const CityDataState.error()),
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _openCityPicker() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CityPickerPage(
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

  List<EventCategory> get _availableCategories =>
      _state.events.map((e) => _resolveCategory(e)).toSet().toList();

  EventCategory _resolveCategory(Event e) => EventCategory.values.firstWhere(
    (c) => c.value.toLowerCase() == e.category.value.toLowerCase(),
    orElse: () => EventCategory.other,
  );

  List<Event> get _dateFiltered {
    final now = DateTime.now();
    return _state.events
        .where(
          (e) => switch (_dateFilter) {
            DateFilter.today => DateUtils.isSameDay(e.start, now),
            DateFilter.week =>
              e.start.isAfter(now) &&
                  e.start.isBefore(now.add(const Duration(days: 7))),
            DateFilter.month =>
              e.start.isAfter(now) &&
                  e.start.isBefore(now.add(const Duration(days: 30))),
            DateFilter.all => true,
          },
        )
        .toList();
  }

  List<Event> get _filtered {
    if (_selectedCategory == null) return _dateFiltered;
    return _dateFiltered
        .where((e) => _resolveCategory(e) == _selectedCategory)
        .toList();
  }

  List<Event> get _featuredEvents {
    final seen = <String>{};
    final result = <Event>[];

    // _filtered is already sorted by date, so first occurrence = soonest
    for (final e in _filtered) {
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
      backgroundColor: const Color(0xFF0A0A0A),
      body: widget.selectedCity == null
          ? _buildEmptyState(context)
          : _buildEventFeed(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
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
                    'Choose a city to\ndiscover events',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.syne(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
                      label: const Text('Pick a city'),
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, compact: true)),

        // Stats card
        SliverToBoxAdapter(child: _buildStatsCard(context)),

        if (_hasData) ...[
          // Date filter
          SliverToBoxAdapter(child: _buildDateFilter(context)),
          // Category chips
          SliverToBoxAdapter(child: _buildCategoryBar(context)),
          // Featured
          if (_filtered.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Featured',
                trailing: DateFormat('EEEE').format(DateTime.now()),
              ),
            ),
            SliverToBoxAdapter(
              child: _FeaturedCarousel(
                events: _featuredEvents.take(5).toList(),
                bookmarked: const {},
                // onToggleBookmark:,
              ),
            ),
          ],
          // All events header
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'All Events',
              trailing: '${_filtered.length} found',
            ),
          ),
          // List
          if (_filtered.isEmpty)
            const SliverToBoxAdapter(child: StatusView.empty())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _EventRow(
                  event: _filtered[i],
                  // isSaved: _bookmarked.contains(_filtered[i].id),
                  // onToggleSave: () => _toggleBookmark(_filtered[i]),
                ),
                childCount: _filtered.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ] else if (_isPolling)
          SliverFillRemaining(
            child: StatusView.loading(
              message: _state.message ?? 'Discovering events…',
            ),
          )
        else
          SliverFillRemaining(
            child: switch (_state.status) {
              CityDataStatus.error => StatusView.withRetry(
                icon: Icons.error_outline,
                message: _state.message ?? 'Something went wrong',
                onRetry: _loadEvents,
              ),
              CityDataStatus.timeout => StatusView.withRetry(
                icon: Icons.timer_off,
                message: _state.message ?? 'Timed out',
                onRetry: _loadEvents,
              ),
              _ => StatusView.loading(message: _state.message ?? 'Loading…'),
            },
          ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, {required bool compact}) {
    final primary = Theme.of(context).colorScheme.primary;
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
                      'DISCOVERING EVENTS IN',
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
                            city?.name ?? 'Choose a city',
                            style: GoogleFonts.syne(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
                    // if (_cityService.locationCity != null) ...[
                    //   const SizedBox(height: 3),
                    //   _CoordLabel(
                    //     lat: _cityService.locationCity!.latitude,
                    //     lon: _cityService.locationCity!.longitude,
                    //   ),
                    // ],
                  ],
                ),
              ),
            ),
            Row(
              children: [
                _IconBtn(
                  icon: Icons.bookmarks_outlined,
                  onTap: () => _showSavedSheet(context),
                  tooltip: 'Saved events',
                ),
                _IconBtn(
                  icon: Icons.language_outlined,
                  onTap: () {},
                  tooltip: 'Region',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Saved events bottom sheet ─────────────────────────────────────────────

  void _showSavedSheet(BuildContext context) {
    final saved = EventCacheService.getBookmarks();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BottomSheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved Events',
                    style: GoogleFonts.syne(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${saved.length} saved',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (saved.isEmpty)
              const Expanded(child: StatusView.empty())
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: saved.length,
                  itemBuilder: (_, i) => _EventRow(
                    event: saved[i],
                    // isSaved: true,
                    // onToggleSave: () async {
                    //   // await EventCacheService.removeBookmark(saved[i].id);
                    //   // setState(() => _bookmarked.remove(saved[i].id));
                    //   // if (ctx.mounted) Navigator.of(ctx).pop();
                    // },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Stats card ───────────────────────────────────────────────────────────────

  Widget _buildStatsCard(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
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
                    _state.message ?? 'Discovering events…',
                    style: TextStyle(fontSize: 13, color: primary),
                  )
                : RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFAAAAAA),
                      ),
                      children: [
                        TextSpan(
                          text: '$count event${count == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' auto-discovered from '),
                        const TextSpan(
                          text: 'schema.org',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // if (((_state.sourceCount ?? 0)) > 0)
                        //   TextSpan(
                        //     text:
                        //         ' across ${_state.sourceCount} source${_state.sourceCount == 1 ? '' : 's'}',
                        //   ),
                      ],
                    ),
                  ),
          ),
          if (_isPolling)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: primary),
            )
          else if (_state.message?.contains('cached') == true)
            Tooltip(
              message: 'Showing offline data',
              child: Icon(
                Icons.cloud_off_outlined,
                size: 15,
                color: Colors.orange.shade300,
              ),
            ),
        ],
      ),
    );
  }

  // ── Date filter ──────────────────────────────────────────────────────────────

  Widget _buildDateFilter(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
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
                    color: sel ? primary : const Color(0xFF2E2E2E),
                  ),
                ),
                child: Text(
                  f.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? Colors.black : const Color(0xFF999999),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Category bar ─────────────────────────────────────────────────────────────

  Widget _buildCategoryBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
              label: Text(cat?.value ?? 'All'),
              selected: sel,
              onSelected: (_) =>
                  setState(() => _selectedCategory = sel ? null : cat),
              showCheckmark: false,
              selectedColor: color,
              backgroundColor: const Color(0xFF181818),
              side: BorderSide(color: sel ? color : const Color(0xFF2E2E2E)),
              labelStyle: TextStyle(
                fontSize: 12,
                color: sel ? Colors.black : const Color(0xFFCCCCCC),
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

// ─────────────────────────────────────────────────────────────────────────────
// Reusable layout widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.syne(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (trailing != null)
            Text(trailing!, style: TextStyle(fontSize: 13, color: primary)),
        ],
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const _IconBtn({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20, color: Colors.white70),
      onPressed: onTap,
      tooltip: tooltip,
      splashRadius: 20,
    );
  }
}

class _FeaturedCarousel extends StatelessWidget {
  final List<Event> events;
  final Set<String> bookmarked;
  // final ValueChanged<Event> onToggleBookmark;
  const _FeaturedCarousel({
    required this.events,
    required this.bookmarked,
    // required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: events.length,
        itemBuilder: (ctx, i) => _FeaturedCard(
          event: events[i],
          isSaved: bookmarked.contains(events[i].id),
          // onToggleSave: () => onToggleBookmark(events[i]),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Event event;
  final bool isSaved;
  // final VoidCallback onToggleSave;

  const _FeaturedCard({
    required this.event,
    required this.isSaved,
    // required this.onToggleSave,
  });

  Color get _catColor {
    return EventCategory.values
        .firstWhere(
          (c) => c.value.toLowerCase() == event.category.value.toLowerCase(),
          orElse: () => EventCategory.other,
        )
        .color;
  }

  IconData get _catIcon {
    return EventCategory.values
        .firstWhere(
          (c) => c.value.toLowerCase() == event.category.value.toLowerCase(),
          orElse: () => EventCategory.other,
        )
        .iconData;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isPast = !event.isUpcoming;

    return GestureDetector(
      onTap: () => _launchUrl(event.url),
      child: Container(
        width: 295,
        margin: const EdgeInsets.only(right: 14, bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          // Layered gradient gives depth without a painter
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _catColor.withValues(alpha: 0.3),
              _catColor.withValues(alpha: 0.08),
              const Color(0xFF0E0E0E),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
          border: Border.all(color: _catColor.withValues(alpha: 0.28)),
        ),
        child: Stack(
          children: [
            // Subtle tinted corner glow — just an opacity container, no painter
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _catColor.withValues(alpha: 0.07),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: category chip + bookmark
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CategoryChip(
                        label: event.category.value,
                        icon: _catIcon,
                        color: _catColor,
                      ),
                      GestureDetector(
                        // onTap: onToggleSave,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            key: ValueKey(isSaved),
                            size: 20,
                            color: isSaved ? primary : const Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Time badge + time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPast
                              ? Colors.red.withValues(alpha: 0.18)
                              : primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPast ? 'PAST' : 'UPCOMING',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: isPast ? Colors.red.shade300 : primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.durationLabel ?? "ERROR",
                        style: GoogleFonts.syne(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Title
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  if (event.venue != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 11,
                          color: _catColor,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            event.venue!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Footer: price + view details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (event.price != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.isFree ? 'Free' : event.price!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: event.isFree ? primary : Colors.white,
                              ),
                            ),
                            if (event.source != null)
                              Text(
                                'via ${Uri.tryParse(event.source ?? '')?.host ?? event.source}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF555555),
                                ),
                              ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),
                      if (event.url != null)
                        GestureDetector(
                          onTap: () => _launchUrl(event.url),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: primary.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// All Events row
// ─────────────────────────────────────────────────────────────────────────────

class _EventRow extends StatelessWidget {
  final Event event;
  // final bool isSaved;
  // final VoidCallback onToggleSave;
  const _EventRow({
    required this.event,
    // required this.isSaved,
    // required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isPast = event.start.isBefore(DateTime.now());
    final catColor = EventCategory.values
        .firstWhere(
          (c) => c.value.toLowerCase() == event.category.value.toLowerCase(),
          orElse: () => EventCategory.other,
        )
        .color;

    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(event.url ?? '');
        if (uri != null && await canLaunchUrl(uri)) launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF181818))),
        ),
        child: Row(
          children: [
            // Date badge
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
                        : DateFormat('MMM').format(event.start).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isPast ? Colors.red.shade400 : primary,
                    ),
                  ),
                  Text(
                    '${event.start.day}',
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
            // Info
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
            // Right: bookmark + category dot + chevron
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () async =>
                      await EventCacheService.toggleBookmark(event),
                  child: const AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    child: Icon(
                      // isSaved
                      //     ? Icons.bookmark_rounded
                      // :
                      Icons.bookmark_outline_rounded,
                      // key: ValueKey(isSaved),
                      size: 19,
                      // color: isSaved ? primary : const Color(0xFF444444),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Category chip
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CityPickerPage extends StatelessWidget {
  final CityItem? initialValue;
  final ValueChanged<CityItem> onCitySelected;

  const _CityPickerPage({
    required this.initialValue,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Choose City',
          style: GoogleFonts.syne(fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF1E1E1E), height: 1),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CityPicker(
          initialValue: initialValue,
          onCitySelected: onCitySelected,
        ),
      ),
    );
  }
}
