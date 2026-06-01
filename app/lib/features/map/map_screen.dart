import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:event_radar/core/models/city_data_state.dart';
import 'package:event_radar/core/models/city_item.dart';
import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/services/city_service.dart';
import 'package:event_radar/core/services/event_service.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/utils/date_filter.dart';
import 'package:event_radar/core/utils/event_dedup.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/core/utils/maps_launcher.dart';
import 'package:event_radar/features/event_details/event_details_screen.dart';
import 'package:event_radar/features/map/widgets/collapsed_event_bubble.dart';
import 'package:event_radar/features/map/widgets/draggable_overlay.dart';
import 'package:event_radar/features/map/widgets/event_marker.dart';
import 'package:event_radar/features/map/widgets/events_chip.dart';
import 'package:event_radar/features/map/widgets/events_panel.dart';
import 'package:event_radar/features/map/widgets/loading_pill.dart';
import 'package:event_radar/features/map/widgets/map_empty_state.dart';
import 'package:event_radar/features/map/widgets/map_fab.dart';
import 'package:event_radar/features/map/widgets/selected_event_card.dart';
import 'package:event_radar/features/map/widgets/user_dot.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';

final _log = Logger('MapScreen');

//* Map tab: clustered event markers, draggable events panel + selected card
class MapScreen extends StatefulWidget {
  final CityItem? city;
  const MapScreen({super.key, this.city});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  //* Space for the bottom tab bar + pop-up overhang (not in MediaQuery padding)
  static const _bottomNavReserved = 110.0;

  final _eventService = EventService.instance;
  final _cityService = CityService.instance;
  final _mapController = MapController();

  StreamSubscription<CityDataState>? _sub;
  List<Event> _events = [];
  CityDataStatus _status = CityDataStatus.polling;
  Event? _selected;
  Position? _userPosition;

  //* Parent owns only expanded/collapsed; each overlay tracks its own offset
  bool _chipExpanded = false;
  bool _cardCollapsed = false;
  final _chipKey = GlobalKey<DraggableOverlayState>();
  final _cardKey = GlobalKey<DraggableOverlayState>();

  @override
  void initState() {
    super.initState();
    _seedUserPosition();
    if (widget.city != null) _loadEvents(widget.city!);
    //* Rebuild so distance pills refresh when the unit changes
    SettingsService.instance.distanceUnit.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(MapScreen old) {
    super.didUpdateWidget(old);
    if (widget.city != old.city && widget.city != null) {
      _loadEvents(widget.city!);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mapController.dispose();
    SettingsService.instance.distanceUnit.removeListener(_onSettingsChanged);
    super.dispose();
  }

  //* Seed the user position from a cached fix, else resolve it
  Future<void> _seedUserPosition() async {
    if (_cityService.lastPosition != null) {
      setState(() => _userPosition = _cityService.lastPosition);
      return;
    }
    await _cityService.resolveLocation();
    if (!mounted) return;
    if (_cityService.lastPosition != null) {
      setState(() => _userPosition = _cityService.lastPosition);
    }
  }

  //* Subscribe to the city's events, keeping only located, non-ended, deduped
  void _loadEvents(CityItem city) {
    _sub?.cancel();
    setState(() {
      _events = [];
      _selected = null;
      _status = CityDataStatus.polling;
    });

    final slug = EventService.slugFor(city);
    _sub = _eventService
        //* includePast keeps ongoing multi-day events; DateFilter.all drops ended
        .getEventsForCity(
          slug,
          countryCode: city.countryCode,
          includePast: true,
        )
        .listen((state) {
          setState(() {
            _status = state.status;
            if (state.events.isNotEmpty) {
              _events = dedupeOverlapping(
                state.events
                    .where((e) => e.hasLocation && DateFilter.all.matches(e))
                    .toList(),
              );
              _fitToEvents();
            }
          });
        });
  }

  //* Get a fresh GPS fix, prompting for permission/settings when interactive
  Future<void> _loadUserPosition({bool interactive = false}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (interactive) {
          await AppSettings.openAppSettings(type: AppSettingsType.location);
        }
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        if (interactive && mounted) {
          _showLocationError(AppL10n.of(context).locationPermissionDenied);
        }
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        if (interactive && mounted) {
          final l = AppL10n.of(context);
          _showLocationError(
            l.locationPermissionDeniedForever,
            actionLabel: l.settings,
            onAction: AppSettings.openAppSettings,
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        //* Base LocationSettings (not AndroidSettings) so it's correct on iOS too
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      if (mounted) setState(() => _userPosition = pos);
    } catch (e, s) {
      _log.warning('loadUserPosition failed', e, s);
      if (interactive && mounted) {
        _showLocationError(AppL10n.of(context).couldNotGetLocation);
      }
    }
  }

  //* Show a location-error snackbar with an optional settings action
  void _showLocationError(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
  }

  //* Fit the camera to all event markers (and the user, if known)
  void _fitToEvents() {
    if (_events.isEmpty) return;
    if (_events.length == 1) {
      _mapController.move(
        LatLng(_events.first.latitude!, _events.first.longitude!),
        13,
      );
      return;
    }
    final points = _events
        .map((e) => LatLng(e.latitude!, e.longitude!))
        .toList();
    final userLatLng = _userLatLng;
    if (userLatLng != null) points.add(userLatLng);
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 160 + _bottomNavReserved),
      ),
    );
  }

  //* Centre the map on the user (requesting a fix if needed)
  Future<void> _centerOnUser() async {
    if (_userPosition == null) {
      await _loadUserPosition(interactive: true);
    }
    final ll = _userLatLng;
    if (ll == null) return;
    _mapController.move(ll, 14);
  }

  //* Empty-map tap collapses an expanded card (never fully dismisses it)
  void _onMapTap() {
    if (_selected == null || _cardCollapsed) return;
    _cardKey.currentState?.recordSnapSide();
    setState(() => _cardCollapsed = true);
  }

  //* Pan to an event and select it
  void _panTo(Event event) {
    _mapController.move(LatLng(event.latitude!, event.longitude!), 15);
    setState(() {
      _selected = event;
      _cardCollapsed = false;
    });
  }

  //* Open external directions to an event
  Future<void> _openDirections(Event event) async {
    final ok = await openDirectionsToEvent(event);
    if (!ok && mounted) {
      _showLocationError(AppL10n.of(context).couldNotOpenMaps);
    }
  }

  //* Push the event details screen
  void _openDetails(Event event) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
    );
  }

  //* Panel list: today's events first, then by start time
  List<Event> get _drawerEvents {
    final list = [..._events];
    list.sort((a, b) {
      final ta = a.isHappeningToday;
      final tb = b.isHappeningToday;
      if (ta != tb) return ta ? -1 : 1;
      return a.start.compareTo(b.start);
    });
    return list;
  }

  //* Count of events happening today
  int get _todayCount => _events.where((e) => e.isHappeningToday).length;

  //* User LatLng, guarded against null/NaN coords (flutter_map throws on those)
  LatLng? get _userLatLng {
    final pos = _userPosition;
    if (pos == null) return null;
    if (!pos.latitude.isFinite || !pos.longitude.isFinite) return null;
    return LatLng(pos.latitude, pos.longitude);
  }

  //* Build one event marker, shared by the cluster and selected-event layers
  Marker _buildEventMarker(Event event) {
    final isSelected = event.id == _selected?.id;
    final today = event.isHappeningToday;
    final size = isSelected ? 46 : (today ? 40 : 32);
    return Marker(
      point: LatLng(event.latitude!, event.longitude!),
      width: size.toDouble(),
      height: size.toDouble(),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selected = isSelected ? null : event;
            if (!isSelected) _cardCollapsed = false;
          });
        },
        child: EventMarker(
          category: event.category,
          isSelected: isSelected,
          isToday: today,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.85),
        elevation: 0,
        title: Text(
          widget.city?.name ?? l.mapTitle,
          style: GoogleFonts.syne(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_events.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  l.eventCount(_events.length),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  //* Map stack: tiles, markers, loading pill, FABs, and the draggable overlays
  Widget _buildBody(BuildContext context) {
    final l = AppL10n.of(context);
    if (widget.city == null) return const MapEmptyState();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            backgroundColor: AppColors.bg,
            initialCenter: const LatLng(52.2297, 21.0122),
            initialZoom: 11,
            onTap: (_, _) => _onMapTap(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.eventradar.app',
            ),
            if (_userLatLng != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLatLng!,
                    width: 22,
                    height: 22,
                    child: const UserDot(),
                  ),
                ],
              ),
            //* Cluster layer holds unselected events; selected is drawn separately
            //* below so it stays visible at any zoom
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 60,
                disableClusteringAtZoom: 16,
                size: const Size(44, 44),
                markers: _events
                    .where((e) => e.id != _selected?.id)
                    .map(_buildEventMarker)
                    .toList(),
                builder: (ctx, markers) {
                  final primary = Theme.of(ctx).colorScheme.primary;
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(blurRadius: 6, color: Colors.black54),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${markers.length}',
                        style: TextStyle(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selected != null &&
                _events.any((e) => e.id == _selected!.id))
              MarkerLayer(markers: [_buildEventMarker(_selected!)]),
          ],
        ),
        if (_status == CityDataStatus.polling ||
            _status == CityDataStatus.triggered)
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: const Center(child: LoadingPill()),
          ),
        Positioned(
          right: 16,
          bottom: 96 + _bottomNavReserved,
          child: Column(
            children: [
              MapFab(
                icon: Icons.fit_screen_rounded,
                onTap: _events.isEmpty ? null : _fitToEvents,
                tooltip: l.fitToEvents,
              ),
              const SizedBox(height: 10),
              MapFab(
                icon: Icons.my_location_rounded,
                onTap: _centerOnUser,
                tooltip: l.myLocation,
              ),
            ],
          ),
        ),
        DraggableOverlay(
          key: _chipKey,
          snapToCorner: !_chipExpanded,
          topReserved: kToolbarHeight,
          bottomReserved: _bottomNavReserved,
          defaultOffset: (screen, padding) =>
              Offset(16, screen.height - padding.bottom - _bottomNavReserved - 60),
          child: _chipExpanded
              ? SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  child: EventsPanel(
                    events: _drawerEvents,
                    todayCount: _todayCount,
                    userPosition: _userPosition,
                    onCollapse: () {
                      _chipKey.currentState?.recordSnapSide();
                      setState(() => _chipExpanded = false);
                    },
                    onSelect: (e) {
                      _chipKey.currentState?.recordSnapSide();
                      setState(() => _chipExpanded = false);
                      _panTo(e);
                    },
                    onOpenDetails: (e) {
                      _chipKey.currentState?.recordSnapSide();
                      setState(() => _chipExpanded = false);
                      _openDetails(e);
                    },
                  ),
                )
              : EventsChip(
                  total: _events.length,
                  todayCount: _todayCount,
                  onTap: () => setState(() => _chipExpanded = true),
                ),
        ),
        if (_selected != null)
          DraggableOverlay(
            key: _cardKey,
            snapToCorner: _cardCollapsed,
            topReserved: kToolbarHeight,
            bottomReserved: _bottomNavReserved,
            defaultOffset: (screen, padding) => Offset(
              88,
              screen.height - padding.bottom - _bottomNavReserved - 170,
            ),
            child: _cardCollapsed
                ? CollapsedEventBubble(
                    event: _selected!,
                    onTap: () => setState(() => _cardCollapsed = false),
                    onClose: () => setState(() {
                      _selected = null;
                      _cardCollapsed = false;
                    }),
                  )
                : SizedBox(
                    width: MediaQuery.of(context).size.width - 104,
                    child: SelectedEventCard(
                      event: _selected!,
                      onCollapse: () {
                        _cardKey.currentState?.recordSnapSide();
                        setState(() => _cardCollapsed = true);
                      },
                      onClose: () => setState(() => _selected = null),
                      onDirections: () => _openDirections(_selected!),
                      onDetails: () => _openDetails(_selected!),
                    ),
                  ),
          ),
      ],
    );
  }
}
