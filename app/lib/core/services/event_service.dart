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

  static String slugFor(CityItem city) =>
      removeDiacritics(city.name).toLowerCase().replaceAll(' ', '-');

  Stream<CityDataState> getEventsForCity(
    String slug, {
    String countryCode = '',
    double? latitude,
    double? longitude,
    DateTime? from,
    DateTime? to,
  }) async* {
    //* Memory cache hit
    if (_isCacheFresh(slug)) {
      yield CityDataState(
        CityDataStatus.fresh,
        events: _filter(_cache[slug]!.events, latitude, longitude, from, to),
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
        events: _filter(events, latitude, longitude, from, to),
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
            events: _filter(events, latitude, longitude, from, to),
          );
          return;
        }
      }
    }

    yield const CityDataState.timeout();
  }

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

  void dispose() => _client.close();

  // Drops the in-memory cache for `slug` so the next getEventsForCity call
  // re-fetches the dataset. Used by pull-to-refresh.
  void invalidateCache(String slug) => _cache.remove(slug);

  bool _isCacheFresh(String slug) {
    final entry = _cache[slug];
    return entry != null && DataFreshness.isMemoryCacheFresh(entry.cachedAt);
  }

  void _setCache(String slug, List<Event> events) =>
      _cache[slug] = (events: events, cachedAt: DateTime.now());

  Uri _datasetUri(String path) =>
      _datasetsBase.replace(queryParameters: {'path': path});

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

  Future<Map<String, dynamic>?> _findInIndex(String cityName) async {
    final cities = await fetchIndex();
    final needle = cityName.toLowerCase();
    return cities
        .where((c) => (c['city'] as String?)?.toLowerCase() == needle)
        .firstOrNull;
  }

  List<Event> _parseEvents(Map<String, dynamic> data) {
    final tzName = (data['timezone'] as String?)?.trim() ?? '';
    return (data['events'] as List? ?? [])
        .map((e) {
          final raw = e as Map<String, dynamic>;
          // Inject dataset-level IANA timezone so each Event knows the venue's
          // tz for display, without Flutter maintaining a country→tz map.
          return Event.fromJson({
            ...raw,
            if (tzName.isNotEmpty) 'timezone': tzName,
          });
        })
        .toList();
  }

  List<Event> _filter(
    List<Event> events,
    double? lat,
    double? lon,
    DateTime? from,
    DateTime? to,
  ) {
    final start = from ?? DateTime.now();
    final end = to ?? start.add(const Duration(days: _defaultWindowDays));
    final hasCoords = lat != null && lon != null;

    final tagged =
        events
            .where((e) => e.start.isAfter(start) && e.start.isBefore(end))
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
