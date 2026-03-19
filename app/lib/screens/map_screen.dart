import 'dart:async';

import 'package:event_radar/models/city_data_state.dart';
import 'package:event_radar/models/city_item.dart';
import 'package:event_radar/models/event.dart';
import 'package:event_radar/models/event_category.dart';
import 'package:event_radar/services/event_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  final CityItem? city;
  const MapScreen({super.key, this.city});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _eventService = EventService.instance;
  final _mapController = MapController();

  StreamSubscription<CityDataState>? _sub;
  List<Event> _events = [];
  CityDataStatus _status = CityDataStatus.polling;
  Event? _selected;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _loadUserPosition();
    if (widget.city != null) _loadEvents(widget.city!);
  }

  @override
  void didUpdateWidget(MapScreen old) {
    super.didUpdateWidget(old);
    if (widget.city != old.city && widget.city != null) {
      _loadEvents(widget.city!);
    }
  }

  void _loadEvents(CityItem city) {
    _sub?.cancel();
    setState(() {
      _events = [];
      _selected = null;
      _status = CityDataStatus.polling;
    });

    final slug = city.name.toLowerCase().replaceAll(' ', '-');

    _sub = _eventService
        .getEventsForCity(slug, countryCode: city.countryCode)
        .listen((state) {
          setState(() {
            _status = state.status;
            if (state.events.isNotEmpty) {
              _events = state.events.where((e) => e.hasLocation).toList();
              _centerOnEvents();
            }
          });
        });
  }

  Future<void> _loadUserPosition() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.low),
      );
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  void _centerOnEvents() {
    if (_events.isEmpty) return;
    final lats = _events.map((e) => e.latitude!);
    final lons = _events.map((e) => e.longitude!);
    final center = LatLng(
      (lats.reduce((a, b) => a + b)) / lats.length,
      (lons.reduce((a, b) => a + b)) / lons.length,
    );
    _mapController.move(center, 12);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.city?.name ?? 'Map'),
        actions: [
          if (_events.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_events.length} events',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.city == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Select a city on the Discover tab to see events on the map.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(52.2297, 21.0122),
            initialZoom: 11,
            onTap: (_, _) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.event_radar',
            ),
            if (_userPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      _userPosition!.latitude,
                      _userPosition!.longitude,
                    ),
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(blurRadius: 4, color: Colors.black26),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            MarkerLayer(
              markers: _events.map((event) {
                final isSelected = event.id == _selected?.id;
                return Marker(
                  point: LatLng(event.latitude!, event.longitude!),
                  width: isSelected ? 44 : 36,
                  height: isSelected ? 44 : 36,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selected = isSelected ? null : event;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: isSelected ? 2 : 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(blurRadius: 4, color: Colors.black26),
                        ],
                      ),
                      child: Icon(
                        event.category.iconData,
                        size: isSelected ? 22 : 18,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        if (_status == CityDataStatus.polling ||
            _status == CityDataStatus.triggered)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Loading events…',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_selected != null)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _EventCard(
              event: _selected!,
              onClose: () => setState(() => _selected = null),
            ),
          ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onClose;

  const _EventCard({required this.event, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (event.venue != null)
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: scheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.venue!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: scheme.primary),
                const SizedBox(width: 4),
                Text(
                  _formatDate(event.start),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (event.price != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.confirmation_number,
                    size: 14,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event.price!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
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
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $h:$m';
  }
}
