import 'dart:async';
import 'dart:convert';

import 'package:diacritic/diacritic.dart';
import 'package:event_radar/core/config.dart';
import 'package:event_radar/core/models/city_data_state.dart';
import 'package:event_radar/core/models/city_item.dart';
import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/utils/data_freshness.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final _log = Logger('EventService');

//* How long to wait between each poll attempt while a scrape is running
const _pollInterval = Duration(seconds: 15);
//* How long to keep polling before giving up entirely
const _pollTimeout = Duration(minutes: 8);
//* Default search radius when coordinates are provided
const _defaultRadiusKm = 25.0;
//* Default event window when no date range is specified
const _defaultWindowDays = 90;

//* Cache
typedef _CacheEntry = ({List<Event> events, DateTime cachedAt});

//* Fetches, caches, and triggers scraping of per-city event datasets
class EventService {
  final http.Client _client;
  final Uri _datasetsBase;
  final Uri _triggerUri;
  final Map<String, _CacheEntry> _cache = {};
  EventService._internal()
    : _client = http.Client(),
      _datasetsBase = Uri.parse(AppConfig.datasetsBase),
      _triggerUri = Uri.parse(AppConfig.triggerUrl);

  static final EventService instance = EventService._internal();

  //* URL-safe slug for a city name
  static String slugFor(CityItem city) =>
      removeDiacritics(city.name).toLowerCase().replaceAll(' ', '-');

  //* Stream a city's events: cache → remote → trigger scrape + poll
  Stream<CityDataState> getEventsForCity(
    String slug, {
    String countryCode = '',
    double? latitude,
    double? longitude,
    DateTime? from,
    DateTime? to,
    //* Keep past events for screens that filter them (Discover); default drops
    bool includePast = false,
  }) async* {
    //* Memory cache hit
    if (_isCacheFresh(slug)) {
      yield CityDataState(
        CityDataStatus.fresh,
        events: _filter(
          _cache[slug]!.events,
          latitude,
          longitude,
          from,
          to,
          includePast,
        ),
      );
      return;
    }

    //* Remote dataset exists and is within the staleness window
    final dataset = await _fetchDataset(slug);
    final datasetTimestamp =
        dataset?['updated_at'] ?? dataset?['generated_at'];
    if (dataset != null && !DataFreshness.isStale(datasetTimestamp)) {
      final events = _parseEvents(dataset);
      _setCache(slug, events);
      yield CityDataState(
        CityDataStatus.fresh,
        events: _filter(events, latitude, longitude, from, to, includePast),
      );
      return;
    }

    //* Data is missing or stale - trigger a scrape and poll for results
    final cityName = dataset?['city'] as String? ?? slug;
    yield const CityDataState.triggered();

    if (!await _triggerScrape(cityName, countryCode: countryCode)) {
      yield const CityDataState.error();
      return;
    }

    final deadline = DateTime.now().add(_pollTimeout);
    while (DateTime.now().isBefore(deadline)) {
      //* Wait before each check to avoid hammering the server
      await Future.delayed(_pollInterval);
      yield const CityDataState.polling();

      final entry = await _findInIndex(cityName);
      if (entry != null && !DataFreshness.isStale(entry['updated_at'])) {
        final fresh = await _fetchDataset(entry['slug'] as String);
        if (fresh != null) {
          final entrySlug = entry['slug'] as String;
          final events = _parseEvents(fresh);
          _setCache(entrySlug, events);
          yield CityDataState(
            CityDataStatus.ready,
            events: _filter(events, latitude, longitude, from, to, includePast),
          );
          return;
        }
      }
    }

    yield const CityDataState.timeout();
  }

  //* Fetch the list of available cities from index.json
  Future<List<Map<String, dynamic>>> fetchIndex() async {
    try {
      final r = await _client.get(_datasetUri('index.json'));
      if (r.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
          (json.decode(r.body) as Map<String, dynamic>)['cities'] ?? [],
        );
      }
      _log.warning('fetchIndex: status ${r.statusCode}');
    } catch (e, s) {
      _log.warning('fetchIndex failed', e, s);
    }
    return [];
  }

  //* Close the HTTP client
  void dispose() => _client.close();

  //* Drop the in-memory cache for a slug so the next call re-fetches (refresh)
  void invalidateCache(String slug) => _cache.remove(slug);

  //* Whether the cached entry for a slug is still within the memory-cache window
  bool _isCacheFresh(String slug) {
    final entry = _cache[slug];
    return entry != null && DataFreshness.isMemoryCacheFresh(entry.cachedAt);
  }

  //* Store events in the memory cache, stamped now
  void _setCache(String slug, List<Event> events) =>
      _cache[slug] = (events: events, cachedAt: DateTime.now());

  //* Build a datasets endpoint URL for a given path
  Uri _datasetUri(String path) =>
      _datasetsBase.replace(queryParameters: {'path': path});

  //* Fetch and decode a single city dataset JSON
  Future<Map<String, dynamic>?> _fetchDataset(String slug) async {
    try {
      final r = await _client.get(_datasetUri('$slug.json'));
      if (r.statusCode == 200) {
        return json.decode(r.body) as Map<String, dynamic>;
      }
      _log.warning('fetchDataset($slug): status ${r.statusCode}');
    } catch (e, s) {
      _log.warning('fetchDataset($slug) failed', e, s);
    }
    return null;
  }

  //* Ask the backend to (re)scrape a city; true if it accepted the request
  Future<bool> _triggerScrape(String city, {String countryCode = ''}) async {
    try {
      final r = await _client.post(
        _triggerUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'city': city, 'country_code': countryCode}),
      );
      if (r.statusCode == 200) {
        final body = json.decode(r.body) as Map<String, dynamic>;
        const acceptedTriggerStatuses = {
          'triggered',
          'fresh',
          'already_running',
        };
        return acceptedTriggerStatuses.contains(body['status']);
      }
      _log.warning('triggerScrape: status ${r.statusCode}');
    } catch (e, s) {
      _log.warning('triggerScrape failed', e, s);
    }
    return false;
  }

  //* Look up a city's index entry by name (case-insensitive)
  Future<Map<String, dynamic>?> _findInIndex(String cityName) async {
    final cities = await fetchIndex();
    final needle = cityName.toLowerCase();
    return cities
        .where((c) => (c['city'] as String?)?.toLowerCase() == needle)
        .firstOrNull;
  }

  //* Parse dataset events, injecting the dataset-level venue timezone into each
  List<Event> _parseEvents(Map<String, dynamic> data) {
    final tzName = (data['timezone'] as String?)?.trim() ?? '';
    return (data['events'] as List? ?? [])
        .map((e) {
          final raw = e as Map<String, dynamic>;
          return Event.fromJson({
            ...raw,
            if (tzName.isNotEmpty) 'timezone': tzName,
          });
        })
        .toList();
  }

  //* Window by date (and radius when coords given), then sort by distance/date
  List<Event> _filter(
    List<Event> events,
    double? lat,
    double? lon,
    DateTime? from,
    DateTime? to,
    bool includePast,
  ) {
    final start = from ?? DateTime.now();
    final end = to ?? start.add(const Duration(days: _defaultWindowDays));
    final hasCoords = lat != null && lon != null;

    final tagged =
        events
            .where(
              (e) =>
                  (includePast || e.start.isAfter(start)) &&
                  e.start.isBefore(end),
            )
            .map(
              (e) =>
                  (event: e, dist: hasCoords ? e.distanceTo(lat, lon) : null),
            )
            .where(
              (r) =>
                  !hasCoords || r.dist == null || r.dist! <= _defaultRadiusKm,
            )
            .toList()
          ..sort(
            (a, b) => hasCoords
                ? (a.dist ?? double.infinity).compareTo(
                    b.dist ?? double.infinity,
                  )
                : a.event.start.compareTo(b.event.start),
          );

    return tagged.map((r) => r.event).toList();
  }
}
