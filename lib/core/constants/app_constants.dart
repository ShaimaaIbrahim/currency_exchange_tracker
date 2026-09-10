/// Cross-cutting configuration values.
abstract final class AppConstants {
  /// Base currency for every request, per the product spec.
  static const String baseCurrencyCode = 'egp';

  /// How many days the detail chart covers, inclusive of today.
  static const int historyWindowDays = 7;

  /// Cached rates older than this are still shown offline, but the UI nudges
  /// the user that they are stale.
  static const Duration cacheStaleAfter = Duration(hours: 12);

  /// Upstream publishes once per day; requests are cheap but not instant.
  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration connectTimeout = Duration(seconds: 10);

  /// How far back to look for the "previous" snapshot used for daily change.
  ///
  /// Yesterday is tried first; if the feed skipped that day (weekend, outage)
  /// we walk back up to this many days before giving up on the delta.
  static const int maxPreviousDayLookback = 4;
}

/// `SharedPreferences` keys. Centralised so a rename cannot silently orphan
/// previously cached data.
abstract final class CacheKeys {
  static const String latestRates = 'cache.latest_rates.v1';
  static const String previousRates = 'cache.previous_rates.v1';
  static const String cachedAt = 'cache.cached_at.v1';
  static String historyFor(String currencyCode) =>
      'cache.history.v1.${currencyCode.toLowerCase()}';
}
