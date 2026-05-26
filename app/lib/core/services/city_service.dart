import 'dart:convert';

import 'package:diacritic/diacritic.dart';
import 'package:event_radar/core/utils/language.dart';
import 'package:event_radar/core/utils/log.dart';
import 'package:extension_utils/string_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:event_radar/core/config.dart';
import 'package:event_radar/core/models/city_item.dart';

class CityService {
  CityService._internal();
  static final CityService instance = CityService._internal();

  static const _recentsBoxName = 'recent_cities';
  static const _recentsKey = 'list';
  static const _recentsCap = 5;

  List<CityItem> _knownCities = [];
  CityItem? locationCity;
  List<CityItem> nearbyCities = [];

  final List<CityItem> _recentCities = [];
  final Map<String, List<CityItem>> _searchCache = {};
  Position? _lastPosition;
  Box<String>? _recentsBox;
  Future<void>? _initFuture;
  Future<bool>? _resolveFuture;

  // The previously-used city, or null on first launch. Returning null lets
  // DiscoverScreen run its location-based resolution instead of silently
  // landing on an arbitrary entry from the published index.
  CityItem? get defaultCity => _recentCities.firstOrNull;

  Position? get lastPosition => _lastPosition;

  static String _normalize(String s) =>
      removeDiacritics(s).toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '-');

  String displayCityName(String raw) {
    if (raw.trim().isEmpty) return raw;
    final key = _normalize(raw);
    for (final c in [..._recentCities, ..._knownCities]) {
      if (_normalize(c.name) == key) return c.name;
    }
    return raw
        .split(RegExp(r'[\s_-]+'))
        .where((s) => s.isNotEmpty)
        .map((s) => s.capitalize())
        .join(' ');
  }

  bool sameCity(String a, String b) => _normalize(a) == _normalize(b);

  Future<void> init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    await Hive.initFlutter();
    _recentsBox = await Hive.openBox<String>(_recentsBoxName);
    _loadRecents();
    _knownCities = await _loadKnownCities();
  }

  void markUsed(CityItem city) {
    _recentCities.remove(city);
    _recentCities.insert(0, city);
    if (_recentCities.length > _recentsCap) _recentCities.removeLast();
    _persistRecents();
  }

  void _loadRecents() {
    final raw = _recentsBox?.get(_recentsKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _recentCities.addAll(
        list.whereType<Map>().map(
          (m) => CityItem(
            m['name'] as String? ?? '',
            m['countryCode'] as String? ?? '',
          ),
        ).where((c) => c.name.isNotEmpty),
      );
    } catch (e, s) {
      Log.warn('CityService', 'corrupted recents entry', e, s);
    }
  }

  void _persistRecents() {
    final box = _recentsBox;
    if (box == null) return;
    final encoded = jsonEncode(
      _recentCities
          .map((c) => {'name': c.name, 'countryCode': c.countryCode})
          .toList(),
    );
    box.put(_recentsKey, encoded);
  }

  Future<List<CityItem>> getItems(
    String filter, {
    String languageCode = 'en',
  }) async {
    final needle = filter.trim().toLowerCase();

    if (needle.isEmpty) return _buildDefaultList();

    final local = _knownCities
        .where((c) => c.name.toLowerCase().startsWith(needle))
        .toList();
    if (local.isNotEmpty) return local;

    if (_searchCache.containsKey(needle)) return _searchCache[needle]!;

    final results = await _searchByPrefix(
      filter.trim(),
      languageCode: languageCode,
    );
    _searchCache[needle] = results;
    return results;
  }

  Future<bool> resolveLocation({
    String languageCode = 'en',
    bool force = false,
  }) {
    if (force) _resolveFuture = null;
    return _resolveFuture ??= _doResolveLocation(languageCode: languageCode);
  }

  Future<bool> _doResolveLocation({String languageCode = 'en'}) async {
    try {
      final pos = await _getPosition();
      if (pos == null) {
        _resolveFuture = null;
        return false;
      }
      _lastPosition = pos;

      final cities = await _fetchNearbyCities(
        pos.latitude,
        pos.longitude,
        languageCode: languageCode,
      );
      if (cities.isEmpty) {
        _resolveFuture = null;
        return false;
      }

      locationCity = cities.first;
      nearbyCities = cities.skip(1).toList();
      return true;
    } catch (e, s) {
      Log.warn('CityService', 'resolveLocation failed', e, s);
      _resolveFuture = null;
      return false;
    }
  }

  List<CityItem> _buildDefaultList() {
    final pinned = <CityItem>{..._recentCities, ?locationCity, ...nearbyCities};
    final rest = _knownCities.where((c) => !pinned.contains(c));
    return [...pinned, ...rest];
  }

  Future<List<CityItem>> _loadKnownCities() async {
    try {
      final uri = Uri.parse(
        AppConfig.datasetsBase,
      ).replace(queryParameters: {'path': 'index.json'});
      final r = await http.get(uri);
      if (r.statusCode != 200) return _fallbackCities;
      final data = json.decode(r.body) as Map<String, dynamic>;
      final cities = (data['cities'] as List? ?? [])
          .map((c) => _parseIndexEntry(c as Map<String, dynamic>))
          .whereType<CityItem>()
          .toList();
      return cities.isNotEmpty ? cities : _fallbackCities;
    } catch (e, s) {
      Log.warn('CityService', 'loadKnownCities failed; using fallback', e, s);
      return _fallbackCities;
    }
  }

  CityItem? _parseIndexEntry(Map<String, dynamic> c) {
    final raw = c['city'] as String?;
    if (raw == null) return null;

    final cc = c['country_code'] as String? ?? '';
    if (cc.isNotEmpty) return CityItem(raw.capitalize(), cc);

    if (raw.contains(':')) {
      final parts = raw.split(':');
      return CityItem(parts[0].trim().capitalize(), parts[1].trim());
    }

    return CityItem(raw.capitalize(), '');
  }

  Uri _geoUri(String path, Map<String, String> params) => Uri.parse(
    '${AppConfig.vercelBase}/api/geodata',
  ).replace(queryParameters: {'path': path, ...params});

  Future<List<CityItem>> _fetchNearbyCities(
    double lat,
    double lon, {
    String languageCode = 'en',
    int limit = 6,
  }) async {
    try {
      final r = await http.get(
        _geoUri('/v1/geo/locations/${_fmtLatLon(lat, lon)}/nearbyCities', {
          'radius': '50',
          'limit': '$limit',
          'sort': '-population',
          'languageCode': resolveApiLanguage(languageCode),
          'types': 'CITY',
        }),
      );
      if (r.statusCode != 200) return [];
      return _parseCities((json.decode(r.body) as Map)['data']);
    } catch (e, s) {
      Log.warn('CityService', 'fetchNearbyCities failed', e, s);
      return [];
    }
  }

  Future<List<CityItem>> _searchByPrefix(
    String prefix, {
    String languageCode = 'en',
  }) async {
    try {
      final params = <String, String>{
        'namePrefix': prefix,
        'limit': '10',
        'sort': '-population',
        'languageCode': resolveApiLanguage(languageCode),
        'types': 'CITY',
      };

      if (_lastPosition != null) {
        params['nearLocation'] = _fmtLatLon(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
        );
        params['nearLocationRadius'] = '500';
      }

      final r = await http.get(_geoUri('/v1/geo/cities', params));
      if (r.statusCode != 200) return [];
      return _parseCities((json.decode(r.body) as Map)['data']);
    } catch (e, s) {
      Log.warn('CityService', 'searchByPrefix failed', e, s);
      return [];
    }
  }

  String _fmtLatLon(double lat, double lon) {
    String s(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(4)}';
    return '${s(lat)}${s(lon)}';
  }

  List<CityItem> _parseCities(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(
          (c) =>
              CityItem(c['name'] as String, c['countryCode'] as String? ?? ''),
        )
        .toList();
  }

  Future<Position?> _getPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.low),
      );
    } catch (e, s) {
      Log.warn('CityService', 'getPosition failed', e, s);
      return null;
    }
  }
}

const _fallbackCities = [CityItem('Wrocław', 'PL'), CityItem('Berlin', 'DE')];
