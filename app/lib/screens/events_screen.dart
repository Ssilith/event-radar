import 'dart:async';

import 'package:app/models/city_data_state.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _sub?.cancel();
    setState(() => _state = const CityDataState.triggered());

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
    _service.dispose();
    super.dispose();
  }

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
                  '${_state.events.length} events',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: switch (_state.status) {
        CityDataStatus.triggered || CityDataStatus.polling =>
          StatusView.loading(message: _state.message ?? 'Loading events…'),

        CityDataStatus.fresh || CityDataStatus.ready =>
          _state.events.isEmpty
              ? const StatusView.empty()
              : EventList(events: _state.events),

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
