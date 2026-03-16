import 'dart:async';
import 'package:app/models/city_data_state.dart';
import 'package:app/models/event.dart';
import 'package:app/services/event_service.dart';
import 'package:app/widgets/event_list.dart';
import 'package:app/widgets/status_view.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';

class EventsScreen extends StatefulWidget {
  final String city;
  final String countryCode;

  const EventsScreen({
    super.key,
    required this.city,
    required this.countryCode,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _service = EventService.instance;
  StreamSubscription<CityDataState>? _sub;
  CityDataState _state = const CityDataState.triggered();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _sub?.cancel();
    setState(() {
      _state = const CityDataState.triggered();
      _selectedCategory = null;
    });

    final slug = removeDiacritics(
      widget.city,
    ).toLowerCase().replaceAll(' ', '-');
    _sub = _service
        .getEventsForCity(slug, countryCode: widget.countryCode)
        .listen(
          (state) => setState(() => _state = state),
          onError: (_) => setState(() => _state = const CityDataState.error()),
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<String> get _categories =>
      _state.events.map((e) => e.category).whereType<String>().toSet().toList()
        ..sort();

  List<Event> get _filtered => _selectedCategory == null
      ? _state.events
      : _state.events.where((e) => e.category == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    final hasResults =
        _state.status == CityDataStatus.fresh ||
        _state.status == CityDataStatus.ready;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.city),
        actions: [
          if (hasResults)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${_filtered.length} events',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: switch (_state.status) {
        CityDataStatus.triggered || CityDataStatus.polling =>
          StatusView.loading(message: _state.message ?? 'Loading events…'),

        CityDataStatus.fresh || CityDataStatus.ready => Column(
          children: [
            if (_categories.isNotEmpty)
              _CategoryBar(
                categories: _categories,
                selected: _selectedCategory,
                onSelected: (cat) => setState(
                  () =>
                      _selectedCategory = _selectedCategory == cat ? null : cat,
                ),
              ),
            Expanded(
              child: _filtered.isEmpty
                  ? const StatusView.empty()
                  : EventList(events: _filtered),
            ),
          ],
        ),

        CityDataStatus.timeout => StatusView.withRetry(
          icon: Icons.timer_off,
          message: _state.message ?? 'Timed out.',
          onRetry: _load,
        ),

        CityDataStatus.error => StatusView.withRetry(
          icon: Icons.error_outline,
          message: _state.message ?? 'Something went wrong.',
          onRetry: _load,
        ),
      },
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  static const _icons = {
    'Music': Icons.music_note,
    'Theater': Icons.theater_comedy,
    'Art': Icons.palette,
    'Festival': Icons.festival,
    'Food': Icons.restaurant,
    'Sports': Icons.sports,
    'Comedy': Icons.sentiment_very_satisfied,
    'Dance': Icons.accessibility_new,
    'Literature': Icons.menu_book,
    'Education': Icons.school,
    'Family': Icons.child_care,
    'Film': Icons.movie,
    'Market': Icons.storefront,
    'Business': Icons.business,
    'Social': Icons.people,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        children: categories.map((cat) {
          final isSelected = selected == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                _icons[cat] ?? Icons.event,
                size: 16,
                color: isSelected ? scheme.onPrimary : scheme.primary,
              ),
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => onSelected(cat),
              showCheckmark: false,
              selectedColor: scheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? scheme.onPrimary : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
