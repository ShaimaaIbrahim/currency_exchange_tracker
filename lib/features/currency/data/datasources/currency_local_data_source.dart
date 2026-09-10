import 'dart:convert';

import 'package:currency_exchange_tracker/core/constants/app_constants.dart';
import 'package:currency_exchange_tracker/core/error/exceptions.dart';
import 'package:currency_exchange_tracker/features/currency/data/models/rates_snapshot_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last successful fetch so the app is useful offline (Module 3).
///
/// `SharedPreferences` is the right storage here: the payload is a single
/// small JSON document read once per launch, so a database would add codegen
/// and migration cost for no benefit.
abstract interface class CurrencyLocalDataSource {
  /// Stores today's and the comparison snapshot together, so a cache read can
  /// never mix a fresh "latest" with a stale "previous".
  Future<void> cacheSnapshots({
    required RatesSnapshotModel latest,
    RatesSnapshotModel? previous,
    DateTime? cachedAt,
  });

  /// Throws [CacheMissException] when nothing has been cached yet.
  Future<CachedSnapshots> readSnapshots();

  Future<void> cacheHistory({
    required String currencyCode,
    required List<RatesSnapshotModel> snapshots,
  });

  /// Returns an empty list rather than throwing: a missing history cache is
  /// normal (the user may never have opened that currency).
  Future<List<RatesSnapshotModel>> readHistory(String currencyCode);

  Future<void> clear();
}

/// What [CurrencyLocalDataSource.readSnapshots] hands back.
class CachedSnapshots {
  const CachedSnapshots({
    required this.latest,
    required this.cachedAt,
    this.previous,
  });

  final RatesSnapshotModel latest;
  final RatesSnapshotModel? previous;

  /// Wall-clock time of the fetch that produced [latest]. This is what the
  /// offline banner reports, so it must be the *fetch* time, not the feed's
  /// publication date.
  final DateTime cachedAt;
}

class CurrencyLocalDataSourceImpl implements CurrencyLocalDataSource {
  const CurrencyLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<void> cacheSnapshots({
    required RatesSnapshotModel latest,
    RatesSnapshotModel? previous,
    DateTime? cachedAt,
  }) async {
    try {
      await _prefs.setString(
        CacheKeys.latestRates,
        jsonEncode(latest.toJson()),
      );
      if (previous == null) {
        await _prefs.remove(CacheKeys.previousRates);
      } else {
        await _prefs.setString(
          CacheKeys.previousRates,
          jsonEncode(previous.toJson()),
        );
      }
      await _prefs.setString(
        CacheKeys.cachedAt,
        (cachedAt ?? DateTime.now()).toIso8601String(),
      );
    } on Object catch (error) {
      throw CacheException(cause: error);
    }
  }

  @override
  Future<CachedSnapshots> readSnapshots() async {
    final rawLatest = _prefs.getString(CacheKeys.latestRates);
    if (rawLatest == null) throw const CacheMissException();

    try {
      final latest = RatesSnapshotModel.fromCacheJson(
        jsonDecode(rawLatest) as Map<String, dynamic>,
      );

      final rawPrevious = _prefs.getString(CacheKeys.previousRates);
      final previous = rawPrevious == null
          ? null
          : RatesSnapshotModel.fromCacheJson(
              jsonDecode(rawPrevious) as Map<String, dynamic>,
            );

      final rawCachedAt = _prefs.getString(CacheKeys.cachedAt);
      final cachedAt = rawCachedAt == null
          ? null
          : DateTime.tryParse(rawCachedAt);

      return CachedSnapshots(
        latest: latest,
        previous: previous,
        // Falling back to the publication date keeps the banner honest if the
        // timestamp key was lost; it is never more recent than the truth.
        cachedAt: cachedAt ?? latest.date,
      );
    } on CacheMissException {
      rethrow;
    } on Object catch (error) {
      // Corrupt payload: drop it so the next successful fetch starts clean
      // instead of the app failing to read the cache forever.
      await clear();
      throw CacheException(cause: error);
    }
  }

  @override
  Future<void> cacheHistory({
    required String currencyCode,
    required List<RatesSnapshotModel> snapshots,
  }) async {
    try {
      final encoded = jsonEncode(
        snapshots.map((snapshot) => snapshot.toJson()).toList(),
      );
      await _prefs.setString(CacheKeys.historyFor(currencyCode), encoded);
    } on Object catch (error) {
      throw CacheException(cause: error);
    }
  }

  @override
  Future<List<RatesSnapshotModel>> readHistory(String currencyCode) async {
    final raw = _prefs.getString(CacheKeys.historyFor(currencyCode));
    if (raw == null) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(RatesSnapshotModel.fromCacheJson)
          .toList();
    } on Object {
      await _prefs.remove(CacheKeys.historyFor(currencyCode));
      return const [];
    }
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(CacheKeys.latestRates);
    await _prefs.remove(CacheKeys.previousRates);
    await _prefs.remove(CacheKeys.cachedAt);
  }
}
