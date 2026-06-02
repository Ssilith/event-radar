//* Remote dataset is stale past this age
const _staleDuration = Duration(days: 30);
//* In-memory cache is served directly within this age
const _cacheInMemory = Duration(hours: 1);

//* Freshness checks for remote datasets and the in-memory cache
class DataFreshness {
  const DataFreshness._();

  //* Check if remote dataset is too old and should be re-scraped
  static bool isStale(dynamic timestamp) {
    if (timestamp == null) return true;
    try {
      return DateTime.now().difference(DateTime.parse(timestamp as String)) >
          _staleDuration;
    } catch (_) {
      return true;
    }
  }

  //* Check if in-memory cache is recent enough to serve directly
  static bool isMemoryCacheFresh(DateTime cachedAt) =>
      DateTime.now().difference(cachedAt) < _cacheInMemory;
}
