import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:event_radar/core/models/city_data_state.dart';
import 'package:event_radar/core/models/city_item.dart';
import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/services/city_service.dart';
import 'package:event_radar/core/services/event_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/core/utils/language.dart';
import 'package:event_radar/core/utils/log.dart';
import 'package:event_radar/features/event_details/event_details_screen.dart';
import 'package:event_radar/features/map/widgets/collapsed_event_bubble.dart';
import 'package:event_radar/features/map/widgets/event_marker.dart';
import 'package:event_radar/features/map/widgets/events_chip.dart';
import 'package:event_radar/features/map/widgets/events_panel.dart';
import 'package:event_radar/features/map/widgets/loading_pill.dart';
import 'package:event_radar/features/map/widgets/map_fab.dart';
import 'package:event_radar/features/map/widgets/selected_event_card.dart';
import 'package:event_radar/features/map/widgets/user_dot.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  final CityItem? city;
  const MapScreen({super.key, this.city});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // HomeScreen's MotionTabBar (62 px) plus the active-tab pop-up overhang
  // sits below this screen's body but isn't reflected in MediaQuery padding.
  static const _bottomNavReserved = 110.0;

  // Minimum drag distance (px) before we treat the gesture as directional;
  // smaller jitter falls back to "snap to nearest edge".
  static const _dragSnapThreshold = 4.0;

  final _eventService = EventService.instance;
  final _cityService = CityService.instance;
  final _mapController = MapController();

  StreamSubscription<CityDataState>? _sub;
  List<Event> _events = [];
  CityDataStatus _status = CityDataStatus.polling;
  Event? _selected;
  Position? _userPosition;

  // Draggable overlay state. Two independent widgets (the events chip and
  // the selected-event card) can be moved around; each tracks an offset,
  // an animating flag (so settle calls can animate), and a collapsed flag.
  Offset? _chipOffset;
  bool _chipAnimating = false;
  bool _chipExpanded = false;
  Offset? _cardOffset;
  bool _cardAnimating = false;
  bool _cardCollapsed = false;
  final _chipKey = GlobalKey();
  final _cardKey = GlobalKey();
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    _seedUserPosition();
    if (widget.city != null) _loadEvents(widget.city!);
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
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────

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

  void _loadEvents(CityItem city) {
    _sub?.cancel();
    setState(() {
      _events = [];
      _selected = null;
      _status = CityDataStatus.polling;
    });

    final slug = EventService.slugFor(city);
    _sub = _eventService
        .getEventsForCity(slug, countryCode: city.countryCode)
        .listen((state) {
          setState(() {
            _status = state.status;
            if (state.events.isNotEmpty) {
              _events = state.events.where((e) => e.hasLocation).toList();
              _fitToEvents();
            }
          });
        });
  }

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
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.low),
      );
      if (mounted) setState(() => _userPosition = pos);
    } catch (e, s) {
      Log.warn('MapScreen', 'loadUserPosition failed', e, s);
      if (interactive && mounted) {
        _showLocationError(AppL10n.of(context).couldNotGetLocation);
      }
    }
  }

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

  // ── Map interactions ────────────────────────────────────────────────────

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
    if (_userPosition != null) {
      points.add(LatLng(_userPosition!.latitude, _userPosition!.longitude));
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 160 + _bottomNavReserved),
      ),
    );
  }

  Future<void> _centerOnUser() async {
    if (_userPosition == null) {
      await _loadUserPosition(interactive: true);
    }
    final pos = _userPosition;
    if (pos == null) return;
    _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
  }

  void _panTo(Event event) {
    _mapController.move(LatLng(event.latitude!, event.longitude!), 15);
    setState(() {
      _selected = event;
      _cardCollapsed = false;
    });
    _settleCardPosition();
  }

  Future<void> _openDirections(Event event) async {
    final lat = event.latitude!;
    final lon = event.longitude!;
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lon',
      if (event.venue != null) 'destination_place': event.venue!,
      'travelmode': 'driving',
      'hl': deviceLanguageCode,
    });

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        _showLocationError(AppL10n.of(context).couldNotOpenMaps);
      }
    } catch (e, s) {
      Log.warn('MapScreen', 'openDirections failed', e, s);
      if (mounted) _showLocationError(AppL10n.of(context).couldNotOpenMaps);
    }
  }

  void _openDetails(Event event) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
    );
  }

  // ── Derived data ────────────────────────────────────────────────────────

  List<Event> get _drawerEvents {
    final list = [..._events];
    list.sort((a, b) {
      final ta = isEventToday(a);
      final tb = isEventToday(b);
      if (ta != tb) return ta ? -1 : 1;
      return a.start.compareTo(b.start);
    });
    return list;
  }

  int get _todayCount => _events.where(isEventToday).length;

  // ── Draggable overlays ──────────────────────────────────────────────────

  void _settleChipPosition() => _settle(
        key: _chipKey,
        getOffset: () => _chipOffset,
        snapToCorner: !_chipExpanded,
        apply: (o) => setState(() {
          _chipOffset = o;
          _chipAnimating = true;
        }),
      );

  void _settleCardPosition() => _settle(
        key: _cardKey,
        getOffset: () => _cardOffset,
        snapToCorner: _cardCollapsed,
        apply: (o) => setState(() {
          _cardOffset = o;
          _cardAnimating = true;
        }),
      );

  // Re-positions an overlay once we know its rendered size: collapsed widgets
  // snap to the nearest corner; expanded ones just stay clamped on-screen.
  void _settle({
    required GlobalKey key,
    required Offset? Function() getOffset,
    required bool snapToCorner,
    required ValueChanged<Offset> apply,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final size = box.size;
      final screen = MediaQuery.of(context).size;
      final padding = MediaQuery.of(context).padding;
      final minY = padding.top + kToolbarHeight + 8;
      final maxX = screen.width - size.width - 16;
      final maxY = screen.height -
          size.height -
          padding.bottom -
          _bottomNavReserved -
          16;
      final cur = getOffset() ?? Offset(16, minY);

      final Offset target;
      if (snapToCorner) {
        final centerX = cur.dx + size.width / 2;
        final centerY = cur.dy + size.height / 2;
        target = Offset(
          centerX < screen.width / 2 ? 16.0 : maxX,
          centerY < screen.height / 2 ? minY : maxY,
        );
      } else {
        target = Offset(
          cur.dx.clamp(16.0, maxX).toDouble(),
          cur.dy.clamp(minY, maxY).toDouble(),
        );
      }

      if (target == cur) return;
      apply(target);
    });
  }

  Widget _draggableOverlay({
    required GlobalKey key,
    required Offset? Function() getOffset,
    required bool Function() getAnimating,
    required void Function(Offset offset, {required bool animating}) setOffset,
    required Offset Function(Size screen, EdgeInsets padding) defaultOffset,
    required Widget child,
  }) {
    final screen = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final offset = getOffset() ?? defaultOffset(screen, padding);
    if (getOffset() == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setOffset(offset, animating: false),
      );
    }
    final minY = padding.top + kToolbarHeight + 8;

    return AnimatedPositioned(
      duration: getAnimating()
          ? const Duration(milliseconds: 280)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onPanStart: (_) {
          _dragStart = getOffset() ?? offset;
          if (getAnimating()) setOffset(_dragStart!, animating: false);
        },
        onPanUpdate: (d) {
          final cur = getOffset() ?? offset;
          setOffset(cur + d.delta, animating: false);
        },
        onPanEnd: (_) {
          final cur = getOffset() ?? offset;
          final start = _dragStart ?? cur;
          _dragStart = null;
          final box = key.currentContext?.findRenderObject() as RenderBox?;
          final size = box?.size ?? Size.zero;
          final maxX = screen.width - size.width - 16;
          final maxY = screen.height -
              size.height -
              padding.bottom -
              _bottomNavReserved -
              16;
          final dx = cur.dx - start.dx;
          final dy = cur.dy - start.dy;

          double snappedX;
          if (dx.abs() < _dragSnapThreshold) {
            final centerX = cur.dx + size.width / 2;
            snappedX = centerX < screen.width / 2 ? 16.0 : maxX;
          } else {
            snappedX = dx < 0 ? 16.0 : maxX;
          }

          double snappedY;
          if (dy.abs() < _dragSnapThreshold) {
            final centerY = cur.dy + size.height / 2;
            snappedY = centerY < screen.height / 2 ? minY : maxY;
          } else {
            snappedY = dy < 0 ? minY : maxY;
          }

          setOffset(Offset(snappedX, snappedY), animating: true);
        },
        child: KeyedSubtree(key: key, child: child),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

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

  Widget _buildBody(BuildContext context) {
    final l = AppL10n.of(context);
    if (widget.city == null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  l.mapNoCitySelected,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            backgroundColor: AppColors.bg,
            initialCenter: const LatLng(52.2297, 21.0122),
            initialZoom: 11,
            onTap: (_, _) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.eventradar.app',
            ),
            if (_userPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      _userPosition!.latitude,
                      _userPosition!.longitude,
                    ),
                    width: 22,
                    height: 22,
                    child: const UserDot(),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                // Selected marker is rendered last so it stacks on top.
                ..._events.where((e) => e.id != _selected?.id),
                if (_selected != null &&
                    _events.any((e) => e.id == _selected!.id))
                  _selected!,
              ].map((event) {
                final isSelected = event.id == _selected?.id;
                final today = isEventToday(event);
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
                      if (!isSelected) _settleCardPosition();
                    },
                    child: EventMarker(
                      category: event.category,
                      isSelected: isSelected,
                      isToday: today,
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
        _draggableOverlay(
          key: _chipKey,
          getOffset: () => _chipOffset,
          getAnimating: () => _chipAnimating,
          setOffset: (o, {required animating}) => setState(() {
            _chipOffset = o;
            _chipAnimating = animating;
          }),
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
                      setState(() => _chipExpanded = false);
                      _settleChipPosition();
                    },
                    onSelect: (e) {
                      setState(() => _chipExpanded = false);
                      _settleChipPosition();
                      _panTo(e);
                    },
                    onOpenDetails: (e) {
                      setState(() => _chipExpanded = false);
                      _settleChipPosition();
                      _openDetails(e);
                    },
                  ),
                )
              : EventsChip(
                  total: _events.length,
                  todayCount: _todayCount,
                  onTap: () {
                    setState(() => _chipExpanded = true);
                    _settleChipPosition();
                  },
                ),
        ),
        if (_selected != null)
          _draggableOverlay(
            key: _cardKey,
            getOffset: () => _cardOffset,
            getAnimating: () => _cardAnimating,
            setOffset: (o, {required animating}) => setState(() {
              _cardOffset = o;
              _cardAnimating = animating;
            }),
            defaultOffset: (screen, padding) => Offset(
              88,
              screen.height - padding.bottom - _bottomNavReserved - 170,
            ),
            child: _cardCollapsed
                ? CollapsedEventBubble(
                    event: _selected!,
                    onTap: () {
                      setState(() => _cardCollapsed = false);
                      _settleCardPosition();
                    },
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
                        setState(() => _cardCollapsed = true);
                        _settleCardPosition();
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
