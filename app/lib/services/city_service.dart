import 'dart:convert';

import 'package:event_radar/utils/language.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:event_radar/config.dart';
import 'package:event_radar/models/city_item.dart';

class CityService {
  CityService._internal();
  static final CityService instance = CityService._internal();

  List<CityItem> _knownCities = [];
  CityItem? locationCity;
  List<CityItem> nearbyCities = [];

  final List<CityItem> _recentCities = [];
  final Map<String, List<CityItem>> _searchCache = {};
  Position? _lastPosition;

  CityItem? get defaultCity =>
      _recentCities.firstOrNull ?? _knownCities.firstOrNull;

  Future<void> init() async {
    _knownCities = await _loadKnownCities();
  }

  void markUsed(CityItem city) {
    _recentCities.remove(city);
    _recentCities.insert(0, city);
    if (_recentCities.length > 5) _recentCities.removeLast();
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

  Future<bool> resolveLocation({String languageCode = 'en'}) async {
    final pos = await _getPosition();
    if (pos == null) return false;
    _lastPosition = pos;

    final cities = await _fetchNearbyCities(
      pos.latitude,
      pos.longitude,
      languageCode: languageCode,
    );
    if (cities.isEmpty) return false;

    locationCity = cities.first;
    nearbyCities = cities.skip(1).toList();
    return true;
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
    } catch (_) {
      return _fallbackCities;
    }
  }

  CityItem? _parseIndexEntry(Map<String, dynamic> c) {
    final raw = c['city'] as String?;
    if (raw == null) return null;
    if (raw.contains(':')) {
      final parts = raw.split(':');
      return CityItem(parts[0].trim(), parts[1].trim());
    }
    return CityItem(raw, '');
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
    } catch (_) {
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
    } catch (_) {
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
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(accuracy: LocationAccuracy.low),
    );
  }
}

const _fallbackCities = [CityItem('Wrocław', 'PL'), CityItem('Berlin', 'DE')];
