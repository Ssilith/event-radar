import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:event_radar/models/city_data_state.dart';
import 'package:event_radar/models/city_item.dart';
import 'package:event_radar/models/event.dart';
import 'package:event_radar/models/event_category.dart';
import 'package:event_radar/screens/event_details_screen.dart';
import 'package:event_radar/services/city_service.dart';
import 'package:event_radar/services/event_service.dart';
import 'package:event_radar/utils/event_time.dart';
import 'package:event_radar/utils/language.dart';
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
  static const _bgColor = Color(0xFF0A0A0A);

  // HomeScreen's MotionTabBar (62 px) plus the active-tab pop-up overhang
  // sits below this screen's body but isn't reflected in MediaQuery padding.
  static const _bottomNavReserved = 110.0;

  // Minimum drag distance (px) before we treat the gesture as directional;
  // smaller jitter falls back to "snap to nearest edge".
  static const _dragSnapThreshold = 4.0;

  Offset? _dragStart;

  void _settleChipPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _chipKey.currentContext?.findRenderObject() as RenderBox?;
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
      final cur = _chipOffset ?? Offset(16, minY);

      Offset target;
      if (_chipExpanded) {
        target = Offset(
          cur.dx.clamp(16.0, maxX).toDouble(),
          cur.dy.clamp(minY, maxY).toDouble(),
        );
      } else {
        final centerX = cur.dx + size.width / 2;
        final centerY = cur.dy + size.height / 2;
        target = Offset(
          centerX < screen.width / 2 ? 16.0 : maxX,
          centerY < screen.height / 2 ? minY : maxY,
        );
      }

      if (target == cur) return;
      setState(() {
        _chipOffset = target;
        _chipAnimating = true;
      });
    });
  }

  void _settleCardPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
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
      final cur = _cardOffset ?? Offset(16, minY);

      Offset target;
      if (_cardCollapsed) {
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
      setState(() {
        _cardOffset = target;
        _cardAnimating = true;
      });
    });
  }

  final _eventService = EventService.instance;
  final _cityService = CityService.instance;
  final _mapController = MapController();

  StreamSubscription<CityDataState>? _sub;
  List<Event> _events = [];
  CityDataStatus _status = CityDataStatus.polling;
  Event? _selected;
  Position? _userPosition;

  Offset? _chipOffset;
  bool _chipAnimating = false;
  bool _chipExpanded = false;
  Offset? _cardOffset;
  bool _cardAnimating = false;
  bool _cardCollapsed = false;
  final _chipKey = GlobalKey();
  final _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _seedUserPosition();
    if (widget.city != null) _loadEvents(widget.city!);
  }

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
        if (interactive) _showLocationError('Location permission denied');
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        if (interactive) {
          _showLocationError(
            'Location permission permanently denied',
            actionLabel: 'Settings',
            onAction: AppSettings.openAppSettings,
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.low),
      );
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {
      if (interactive) _showLocationError('Could not get your location');
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
      if (!ok) _showLocationError('Could not open Google Maps');
    } catch (_) {
      _showLocationError('Could not open Google Maps');
    }
  }

  void _openDetails(Event event) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
    );
  }

  static bool _isToday(Event e) =>
      DateUtils.isSameDay(eventWallClock(e), nowInVenueTz(e.timezone));

  List<Event> get _drawerEvents {
    final list = [..._events];
    list.sort((a, b) {
      final ta = _isToday(a);
      final tb = _isToday(b);
      if (ta != tb) return ta ? -1 : 1;
      return a.start.compareTo(b.start);
    });
    return list;
  }

  int get _todayCount => _events.where(_isToday).length;

  @override
  void dispose() {
    _sub?.cancel();
    _mapController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: _bgColor.withValues(alpha: 0.85),
        elevation: 0,
        title: Text(
          widget.city?.name ?? 'Map',
          style: GoogleFonts.syne(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_events.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_events.length} events',
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
    if (widget.city == null) {
      return const SafeArea(
        child: Center(
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
                  style: TextStyle(color: Colors.white70),
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
            backgroundColor: _bgColor,
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
                    child: const _UserDot(),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                ..._events.where((e) => e.id != _selected?.id),
                if (_selected != null &&
                    _events.any((e) => e.id == _selected!.id))
                  _selected!,
              ].map((event) {
                final isSelected = event.id == _selected?.id;
                final isToday = _isToday(event);
                final size = isSelected ? 46 : (isToday ? 40 : 32);
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
                    child: _EventMarker(
                      category: event.category,
                      isSelected: isSelected,
                      isToday: isToday,
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
            child: const Center(child: _LoadingPill()),
          ),
        Positioned(
          right: 16,
          bottom: 96 + _bottomNavReserved,
          child: Column(
            children: [
              _MapFab(
                icon: Icons.fit_screen_rounded,
                onTap: _events.isEmpty ? null : _fitToEvents,
                tooltip: 'Fit to events',
              ),
              const SizedBox(height: 10),
              _MapFab(
                icon: Icons.my_location_rounded,
                onTap: _centerOnUser,
                tooltip: 'My location',
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
                  child: _EventsPanel(
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
              : _EventsChip(
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
                ? _CollapsedEventBubble(
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
                    child: _SelectedEventCard(
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

// ─────────────────────────────────────────────────────────────────────────────
// Markers
// ─────────────────────────────────────────────────────────────────────────────

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.blueAccent.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

class _EventMarker extends StatelessWidget {
  final EventCategory category;
  final bool isSelected;
  final bool isToday;

  const _EventMarker({
    required this.category,
    required this.isSelected,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    final filled = isSelected || isToday;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: filled ? color : const Color(0xFF161616),
        shape: BoxShape.circle,
        border: Border.all(
          color: isToday ? Colors.white : color,
          width: isSelected ? 2.5 : (isToday ? 2 : 1.5),
        ),
        boxShadow: [
          if (isToday)
            BoxShadow(
              blurRadius: 12,
              spreadRadius: 1,
              color: color.withValues(alpha: 0.6),
            )
          else
            const BoxShadow(blurRadius: 4, color: Colors.black54),
        ],
      ),
      child: Icon(
        category.iconData,
        size: isSelected ? 22 : (isToday ? 20 : 16),
        color: filled ? Colors.black : color,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlays
// ─────────────────────────────────────────────────────────────────────────────

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  const _MapFab({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: const Color(0xFF161616),
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? primary : const Color(0xFF555555),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventsChip extends StatelessWidget {
  final int total;
  final int todayCount;
  final VoidCallback onTap;
  const _EventsChip({
    required this.total,
    required this.todayCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: const Color(0xFF161616),
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_note_rounded, size: 16, color: primary),
              const SizedBox(width: 8),
              Text(
                '$total event${total == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (todayCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$todayCount today',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: 10),
          Text('Loading events…', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _CollapsedEventBubble extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback onClose;
  const _CollapsedEventBubble({
    required this.event,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = event.category.color;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: const Color(0xFF111111),
          shape: const CircleBorder(),
          elevation: 8,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: catColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: catColor.withValues(alpha: 0.4),
                  ),
                ],
              ),
              child: Icon(event.category.iconData, size: 26, color: catColor),
            ),
          ),
        ),
        Positioned(
          right: -4,
          top: -4,
          child: Material(
            color: const Color(0xFF222222),
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: Icon(Icons.close, size: 12, color: Colors.white70),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onClose;
  final VoidCallback onCollapse;
  final VoidCallback onDirections;
  final VoidCallback onDetails;

  const _SelectedEventCard({
    required this.event,
    required this.onClose,
    required this.onCollapse,
    required this.onDirections,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final catColor = event.category.color;

    return Material(
      color: const Color(0xFF111111),
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onDetails,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      event.category.iconData,
                      size: 16,
                      color: catColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.remove_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                    onPressed: onCollapse,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    tooltip: 'Collapse',
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white54,
                    ),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    tooltip: 'Dismiss',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 12, color: primary),
                  const SizedBox(width: 4),
                  Text(
                    formatEventTime(event, 'EEE d MMM, HH:mm'),
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 11,
                    ),
                  ),
                  if (event.venue != null) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.location_on_rounded, size: 12, color: primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.venue!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: const Text('Directions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text('Details'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline expandable events panel (chip's expanded form)
// ─────────────────────────────────────────────────────────────────────────────

class _EventsPanel extends StatelessWidget {
  final List<Event> events;
  final int todayCount;
  final Position? userPosition;
  final VoidCallback onCollapse;
  final ValueChanged<Event> onSelect;
  final ValueChanged<Event> onOpenDetails;

  const _EventsPanel({
    required this.events,
    required this.todayCount,
    required this.userPosition,
    required this.onCollapse,
    required this.onSelect,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: const Color(0xFF111111),
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 6, 6),
                child: Row(
                  children: [
                    Icon(Icons.event_note_rounded, size: 16, color: primary),
                    const SizedBox(width: 8),
                    Text(
                      'Events',
                      style: GoogleFonts.syne(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      todayCount > 0
                          ? '$todayCount today'
                          : '${events.length} upcoming',
                      style: TextStyle(color: primary, fontSize: 12),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_rounded,
                        size: 18,
                        color: Colors.white70,
                      ),
                      onPressed: onCollapse,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(),
                      tooltip: 'Collapse',
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF222222), height: 1),
              if (events.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                      'No events to show.',
                      style: TextStyle(color: Color(0xFF888888)),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: events.length,
                    itemBuilder: (_, i) => _NearbyEventRow(
                      event: events[i],
                      userPosition: userPosition,
                      isToday: _MapScreenState._isToday(events[i]),
                      onTap: () => onSelect(events[i]),
                      onOpenDetails: () => onOpenDetails(events[i]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyEventRow extends StatelessWidget {
  final Event event;
  final Position? userPosition;
  final bool isToday;
  final VoidCallback onTap;
  final VoidCallback onOpenDetails;

  const _NearbyEventRow({
    required this.event,
    required this.userPosition,
    required this.isToday,
    required this.onTap,
    required this.onOpenDetails,
  });

  String? get _distanceLabel {
    final pos = userPosition;
    if (pos == null) return null;
    final km = event.distanceTo(pos.latitude, pos.longitude);
    if (km == null) return null;
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final catColor = event.category.color;
    final distance = _distanceLabel;

    return InkWell(
      onTap: onTap,
      onLongPress: onOpenDetails,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
        decoration: BoxDecoration(
          color: isToday ? primary.withValues(alpha: 0.05) : null,
          border: const Border(
            bottom: BorderSide(color: Color(0xFF1A1A1A)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isToday
                    ? catColor.withValues(alpha: 0.3)
                    : catColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isToday
                      ? catColor
                      : catColor.withValues(alpha: 0.35),
                  width: isToday ? 1.5 : 1,
                ),
              ),
              child: Icon(event.category.iconData, size: 18, color: catColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isToday) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 11, color: primary),
                      const SizedBox(width: 3),
                      Text(
                        isToday
                            ? formatEventTime(event, 'HH:mm')
                            : formatEventTime(event, 'd MMM • HH:mm'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                      if (event.venue != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            event.venue!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (distance != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  distance,
                  style: TextStyle(
                    color: primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF3A3A3A),
              ),
          ],
        ),
      ),
    );
  }
}
