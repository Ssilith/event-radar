import 'dart:async';
import 'package:flutter/material.dart';
import 'config.dart';
import 'models/event.dart';
import 'services/event_service.dart';

void main() {
  AppConfig.validate();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventRadar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('EventRadar'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 24),
            const Text('Pick a city to see upcoming events'),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.location_city),
              label: const Text('Browse Wrocław events'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const EventsScreen(city: 'Wrocław', countryCode: 'PL'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  final _service = EventService();
  StreamSubscription<CityDataState>? _sub;
  CityDataState _state = const CityDataState(CityDataStatus.polling);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _sub?.cancel();
    setState(() => _state = const CityDataState(CityDataStatus.polling));

    _sub = _service
        .getEventsForCity(
          widget.city.toLowerCase().replaceAll(' ', '-'),
          countryCode: widget.countryCode,
        )
        .listen(
          (state) => setState(() => _state = state),
          onError: (e) {
            print(e);
            setState(
              () => _state = const CityDataState(
                CityDataStatus.error,
                message: 'Something went wrong.',
              ),
            );
          },
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.city),
        actions: [
          if (_state.status == CityDataStatus.fresh ||
              _state.status == CityDataStatus.ready)
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
        CityDataStatus.polling || CityDataStatus.triggered => _StatusView(
          icon: Icons.radar,
          message: _state.message ?? 'Loading events…',
          showSpinner: true,
        ),

        CityDataStatus.fresh || CityDataStatus.ready =>
          _state.events.isEmpty
              ? const _StatusView(
                  icon: Icons.search_off,
                  message: 'No upcoming events found for this city.',
                )
              : _EventList(events: _state.events),

        CityDataStatus.timeout => _StatusView(
          icon: Icons.timer_off,
          message: _state.message ?? 'Timed out.',
          action: TextButton(onPressed: _load, child: const Text('Retry')),
        ),

        CityDataStatus.error => _StatusView(
          icon: Icons.error_outline,
          message: _state.message ?? 'Something went wrong.',
          action: TextButton(onPressed: _load, child: const Text('Try again')),
        ),
      },
    );
  }
}

class _EventList extends StatelessWidget {
  final List<Event> events;
  const _EventList({required this.events});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: events.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final event = events[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              _monthDay(event.start),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          title: Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: event.venue != null
              ? Text(
                  event.venue!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : null,
          trailing: event.price != null
              ? Text(event.price!, style: Theme.of(context).textTheme.bodySmall)
              : null,
        );
      },
    );
  }

  String _monthDay(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]}\n${dt.day}';
  }
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool showSpinner;
  final Widget? action;

  const _StatusView({
    required this.icon,
    required this.message,
    this.showSpinner = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
