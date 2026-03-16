const _staleDuration = Duration(days: 30);
const _cacheInMemory = Duration(hours: 1);

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
