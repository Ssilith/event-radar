import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/event.dart';

const _staleDuration = Duration(days: 30);
const _pollInterval = Duration(seconds: 15);
const _pollTimeout = Duration(minutes: 8);
const _cacheInMemory = Duration(hours: 1);

enum CityDataStatus { fresh, triggered, polling, ready, timeout, error }

class CityDataState {
  final CityDataStatus status;
  final List<Event> events;
  final String? message;
  const CityDataState(this.status, {this.events = const [], this.message});
}

class EventService {
  final http.Client _client;
  final Map<String, List<Event>> _cache = {};
  final Map<String, DateTime> _cacheTimes = {};

  String get _datasetsBase => AppConfig.datasetsBase;
  String get _triggerUrl => AppConfig.triggerUrl;

  EventService({http.Client? client}) : _client = client ?? http.Client();

  Stream<CityDataState> getEventsForCity(
    String slug, {
    String countryCode = '',
    double? latitude,
    double? longitude,
    DateTime? from,
    DateTime? to,
  }) async* {
    if (_isCacheFresh(slug)) {
      yield CityDataState(
        CityDataStatus.fresh,
        events: _filter(_cache[slug]!, latitude, longitude, from, to),
      );
      return;
    }

    final dataset = await _fetchDataset(slug);
    if (dataset != null && !_isStale(dataset['generated_at'])) {
      final events = _parseEvents(dataset);
      _setCache(slug, events);
      yield CityDataState(
        CityDataStatus.fresh,
        events: _filter(events, latitude, longitude, from, to),
      );
      return;
    }

    final cityName = dataset?['city'] as String? ?? slug;
    yield const CityDataState(
      CityDataStatus.triggered,
      message:
          'Discovering events — usually takes about 2 minutes the first time.',
    );

    if (!await _triggerScrape(cityName, countryCode: countryCode)) {
      yield const CityDataState(
        CityDataStatus.error,
        message: 'Could not start event discovery. Try again later.',
      );
      return;
    }

    final deadline = DateTime.now().add(_pollTimeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(_pollInterval);
      yield const CityDataState(
        CityDataStatus.polling,
        message: 'Still discovering events…',
      );

      final entry = await _findInIndex(cityName);
      if (entry != null && !_isStale(entry['updated_at'])) {
        final fresh = await _fetchDataset(entry['slug'] as String);
        if (fresh != null) {
          final events = _parseEvents(fresh);
          _setCache(entry['slug'] as String, events);
          yield CityDataState(
            CityDataStatus.ready,
            events: _filter(events, latitude, longitude, from, to),
          );
          return;
        }
      }
    }

    yield const CityDataState(
      CityDataStatus.timeout,
      message:
          'Discovery is taking longer than expected. Check back in a few minutes.',
    );
  }

  Future<List<Map<String, dynamic>>> fetchIndex() async {
    try {
      final uri = Uri.parse(
        _datasetsBase,
      ).replace(queryParameters: {'path': 'index.json'});
      final r = await _client.get(uri);
      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['cities'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  void dispose() => _client.close();

  bool _isCacheFresh(String slug) {
    final t = _cacheTimes[slug];
    return t != null && DateTime.now().difference(t) < _cacheInMemory;
  }

  void _setCache(String slug, List<Event> events) {
    _cache[slug] = events;
    _cacheTimes[slug] = DateTime.now();
  }

  Future<Map<String, dynamic>?> _fetchDataset(String slug) async {
    try {
      final uri = Uri.parse(
        _datasetsBase,
      ).replace(queryParameters: {'path': '$slug.json'});
      final r = await _client.get(uri);
      if (r.statusCode == 200) {
        return json.decode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _triggerScrape(String city, {String countryCode = ''}) async {
    try {
      final r = await _client.post(
        Uri.parse(_triggerUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'city': city, 'country_code': countryCode}),
      );
      if (r.statusCode == 200) {
        final body = json.decode(r.body) as Map<String, dynamic>;
        return body['status'] == 'triggered' ||
            body['status'] == 'fresh' ||
            body['status'] == 'already_running';
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>?> _findInIndex(String cityName) async {
    try {
      final uri = Uri.parse(
        _datasetsBase,
      ).replace(queryParameters: {'path': 'index.json'});
      final r = await _client.get(uri);
      if (r.statusCode != 200) return null;
      final cities = (json.decode(r.body)['cities'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final needle = cityName.toLowerCase();
      return cities
          .where((c) => (c['city'] as String?)?.toLowerCase() == needle)
          .firstOrNull;
    } catch (_) {
      return null;
    }
  }

  List<Event> _parseEvents(Map<String, dynamic> data) =>
      (data['events'] as List? ?? [])
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();

  List<Event> _filter(
    List<Event> events,
    double? lat,
    double? lon,
    DateTime? from,
    DateTime? to,
  ) {
    final start = from ?? DateTime.now();
    final end = to ?? start.add(const Duration(days: 7));
    return events
        .where((e) => e.start.isAfter(start) && e.start.isBefore(end))
        .where((e) {
          if (lat == null || lon == null) return true;
          final d = e.distanceTo(lat, lon);
          return d == null || d <= 25.0;
        })
        .toList()
      ..sort((a, b) {
        if (lat == null || lon == null) return a.start.compareTo(b.start);
        final da = a.distanceTo(lat, lon) ?? 999.0;
        final db = b.distanceTo(lat, lon) ?? 999.0;
        return da.compareTo(db);
      });
  }

  static bool _isStale(dynamic generatedAt) {
    if (generatedAt == null) return true;
    try {
      return DateTime.now().difference(DateTime.parse(generatedAt as String)) >
          _staleDuration;
    } catch (_) {
      return true;
    }
  }
}
