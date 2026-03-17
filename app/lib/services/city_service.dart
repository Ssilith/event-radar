import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:event_radar/config.dart';
import 'package:event_radar/models/city_item.dart';

class CityService {
  CityService._internal();
  static final CityService instance = CityService._internal();

  List<CityItem> knownCities = [];

  CityItem? locationCity;
  List<CityItem> nearbyCities = [];

  final Map<String, List<CityItem>> _searchCache = {};

  Future<void> init() async {
    knownCities = await _loadKnownCities();
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

  Future<List<CityItem>> getItems(String filter) async {
    if (filter.trim().isEmpty) {
      if (locationCity != null) {
        final nearby = [
          locationCity!,
          ...nearbyCities.where((c) => c != locationCity),
        ];
        final rest = knownCities.where((c) => !nearby.contains(c)).toList();
        return [...nearby, ...rest];
      }
      return knownCities;
    }

    final needle = filter.trim().toLowerCase();
    final local = knownCities
        .where((c) => c.name.toLowerCase().startsWith(needle))
        .toList();
    if (local.isNotEmpty) return local;

    final key = needle;
    if (_searchCache.containsKey(key)) return _searchCache[key]!;
    final results = await _searchByPrefix(filter.trim());
    _searchCache[key] = results;
    return results;
  }

  Future<bool> resolveLocation() async {
    final pos = await _getPosition();
    if (pos == null) return false;

    locationCity = await _reverseGeocode(pos.latitude, pos.longitude);
    nearbyCities = await _fetchNearby(pos.latitude, pos.longitude);
    return locationCity != null;
  }

  Uri _geoUri(String path, Map<String, String> params) => Uri.parse(
    '${AppConfig.vercelBase}/api/geodata',
  ).replace(queryParameters: {'path': path, ...params});

  Future<List<CityItem>> _fetchNearby(double lat, double lon) async {
    try {
      final latStr = '${lat >= 0 ? '+' : ''}${lat.toStringAsFixed(4)}';
      final lonStr = '${lon >= 0 ? '+' : ''}${lon.toStringAsFixed(4)}';
      final r = await http.get(
        _geoUri('/v1/geo/locations/$latStr$lonStr/nearbyCities', {
          'radius': '150',
          'limit': '8',
          'minPopulation': '50000',
          'sort': '-population',
        }),
      );
      if (r.statusCode != 200) return [];
      return _parseCities((json.decode(r.body) as Map)['data']);
    } catch (_) {
      return [];
    }
  }

  Future<CityItem?> _reverseGeocode(double lat, double lon) async {
    try {
      final latStr = '${lat >= 0 ? '+' : ''}${lat.toStringAsFixed(4)}';
      final lonStr = '${lon >= 0 ? '+' : ''}${lon.toStringAsFixed(4)}';
      final r = await http.get(
        _geoUri('/v1/geo/locations/$latStr$lonStr/nearbyCities', {
          'radius': '25',
          'limit': '1',
          'sort': '-population',
        }),
      );
      if (r.statusCode != 200) return null;
      final cities = _parseCities((json.decode(r.body) as Map)['data']);
      return cities.isNotEmpty ? cities.first : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<CityItem>> _searchByPrefix(String prefix) async {
    try {
      final r = await http.get(
        _geoUri('/v1/geo/cities', {
          'namePrefix': prefix,
          'limit': '10',
          'sort': '-population',
        }),
      );
      if (r.statusCode != 200) return [];
      return _parseCities((json.decode(r.body) as Map)['data']);
    } catch (_) {
      return [];
    }
  }

  List<CityItem> _parseCities(dynamic data) {
    if (data is! List<Map>) return [];
    return data
        .map((c) => CityItem(c['name'] as String, c['countryCode'] as String))
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
