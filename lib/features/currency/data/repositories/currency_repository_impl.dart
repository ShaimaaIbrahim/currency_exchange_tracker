import 'package:currency_exchange_tracker/core/constants/app_constants.dart';
import 'package:currency_exchange_tracker/core/constants/app_strings.dart';
import 'package:currency_exchange_tracker/core/error/exceptions.dart';
import 'package:currency_exchange_tracker/core/error/failures.dart';
import 'package:currency_exchange_tracker/core/extensions/date_time_x.dart';
import 'package:currency_exchange_tracker/core/network/network_info.dart';
import 'package:currency_exchange_tracker/core/utils/result.dart';
import 'package:currency_exchange_tracker/features/currency/data/datasources/currency_local_data_source.dart';
import 'package:currency_exchange_tracker/features/currency/data/datasources/currency_remote_data_source.dart';
import 'package:currency_exchange_tracker/features/currency/data/mappers/failure_mapper.dart';
import 'package:currency_exchange_tracker/features/currency/data/models/rates_snapshot_model.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency_rate.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rates_board.dart';
import 'package:currency_exchange_tracker/features/currency/domain/repositories/currency_repository.dart';

/// Coordinates network, cache and clock to satisfy [CurrencyRepository].
///
/// The policy it implements, in order:
/// 1. Offline → serve cache, or fail with [OfflineFailure] if the cache is
///    empty.
/// 2. Online → fetch, write through to cache, return network data.
/// 3. Online but the fetch failed → fall back to cache if we have any, so a
///    transient outage degrades instead of breaking. Only when there is no
///    cache does the network failure reach the user.
class CurrencyRepositoryImpl implements CurrencyRepository {
  CurrencyRepositoryImpl({
    required CurrencyRemoteDataSource remote,
    required CurrencyLocalDataSource local,
    required NetworkInfo networkInfo,
    DateTime Function()? clock,
  }) : _remote = remote,
       _local = local,
       _networkInfo = networkInfo,
       _now = clock ?? DateTime.now;

  final CurrencyRemoteDataSource _remote;
  final CurrencyLocalDataSource _local;
  final NetworkInfo _networkInfo;

  /// Injectable clock. Time is an input, and tests that assert on "yesterday"
  /// must not depend on the day they are run.
  final DateTime Function() _now;

  @override
  Future<Result<RatesBoard>> getRatesBoard({bool forceRefresh = false}) async {
    if (!await _networkInfo.isConnected) {
      return _boardFromCache(fallbackFailure: const OfflineFailure());
    }

    try {
      final latest = await _remote.fetchLatest();
      final previous = await _findPreviousSnapshot(latest.date);

      // Write through before returning: if the process dies right after this
      // fetch, the user still opens to real data next launch.
      await _safeCache(latest: latest, previous: previous);

      return Ok(
        _buildBoard(
          latest: latest,
          previous: previous,
          retrievedAt: _now(),
          source: RatesSource.network,
        ),
      );
    } on Object catch (error) {
      // A live network that still failed: prefer stale-but-real data over an
      // error screen, and let the UI label it as cached.
      return _boardFromCache(
        fallbackFailure: FailureMapper.fromException(error),
      );
    }
  }

  @override
  Future<Result<RateHistory>> getRateHistory({
    required Currency currency,
    int days = AppConstants.historyWindowDays,
  }) async {
    final window = _historyWindow(days);

    if (!await _networkInfo.isConnected) {
      return _historyFromCache(
        currency: currency,
        days: days,
        fallbackFailure: const OfflineFailure(),
      );
    }

    // One request per date, in parallel. Individual days are allowed to fail:
    // the feed skips publication days, and a 6-point chart beats no chart.
    final results = await Future.wait(
      window.map(_fetchSnapshotOrNull),
      eagerError: false,
    );

    final snapshots = results.whereType<RatesSnapshotModel>().toList();

    if (snapshots.isEmpty) {
      return _historyFromCache(
        currency: currency,
        days: days,
        fallbackFailure: const NoDataFailure(
          message: AppStrings.historyUnavailable,
        ),
      );
    }

    await _safeCacheHistory(currency: currency, snapshots: snapshots);

    final history = _buildHistory(
      currency: currency,
      snapshots: snapshots,
      days: days,
    );

    if (history.isEmpty) {
      return Err(
        NoDataFailure(
          message: AppStrings.historyMissingCurrency(currency.code),
        ),
      );
    }

    return Ok(history);
  }

  @override
  Stream<bool> watchConnectivity() => _networkInfo.onStatusChange;

  @override
  Future<bool> isConnected() => _networkInfo.isConnected;

  // ── Board assembly ────────────────────────────────────────────────────────

  /// Walks back day by day until a snapshot is found to compare against.
  ///
  /// "Yesterday" is not guaranteed to exist — the feed has gaps — so a single
  /// failed call must not cost the user the entire change column.
  Future<RatesSnapshotModel?> _findPreviousSnapshot(DateTime latestDate) async {
    for (
      var offset = 1;
      offset <= AppConstants.maxPreviousDayLookback;
      offset++
    ) {
      final candidate = latestDate.subtract(Duration(days: offset));
      final snapshot = await _fetchSnapshotOrNull(candidate);
      if (snapshot != null) return snapshot;
    }
    return null;
  }

  /// Fetches one date, swallowing only the failures that mean "no data here".
  Future<RatesSnapshotModel?> _fetchSnapshotOrNull(DateTime date) async {
    try {
      return await _remote.fetchByDate(date);
    } on RatesNotPublishedException {
      return null;
    } on ParsingException {
      return null;
    } on ClientRequestException {
      return null;
    } on Object {
      // Transport-level problems are also tolerated per-date; the caller
      // decides what to do when *every* date failed.
      return null;
    }
  }

  RatesBoard _buildBoard({
    required RatesSnapshotModel latest,
    required RatesSnapshotModel? previous,
    required DateTime retrievedAt,
    required RatesSource source,
  }) {
    final rates = <CurrencyRate>[];

    for (final currency in Currency.values) {
      final quote = latest.quoteFor(currency.responseKey);
      // A currency missing from the payload is dropped rather than rendered as
      // zero; the list shows what we actually know.
      if (quote == null) continue;

      rates.add(
        CurrencyRate.fromEgpQuotes(
          currency: currency,
          unitsPerEgp: quote,
          asOf: latest.date,
          previousUnitsPerEgp: previous?.quoteFor(currency.responseKey),
          previousAsOf: previous?.date,
        ),
      );
    }

    return RatesBoard(
      rates: rates,
      retrievedAt: retrievedAt,
      publishedAt: latest.date,
      source: source,
    );
  }

  Future<Result<RatesBoard>> _boardFromCache({
    required Failure fallbackFailure,
  }) async {
    try {
      final cached = await _local.readSnapshots();
      final board = _buildBoard(
        latest: cached.latest,
        previous: cached.previous,
        retrievedAt: cached.cachedAt,
        source: RatesSource.cache,
      );
      if (board.isEmpty) return Err(fallbackFailure);
      return Ok(board);
    } on Object {
      return Err(fallbackFailure);
    }
  }

  // ── History assembly ──────────────────────────────────────────────────────

  /// The [days] calendar dates to request, oldest first, ending today.
  List<DateTime> _historyWindow(int days) {
    final today = _now().dateOnly;
    return List<DateTime>.generate(
      days,
      (index) => today.subtract(Duration(days: days - 1 - index)),
    );
  }

  RateHistory _buildHistory({
    required Currency currency,
    required List<RatesSnapshotModel> snapshots,
    required int days,
  }) {
    final points = <RatePoint>[];

    for (final snapshot in snapshots) {
      final quote = snapshot.quoteFor(currency.responseKey);
      if (quote == null || quote <= 0) continue;
      points.add(RatePoint(date: snapshot.date, egpPerUnit: 1 / quote));
    }

    points.sort((a, b) => a.date.compareTo(b.date));

    return RateHistory(currency: currency, points: points, requestedDays: days);
  }

  Future<Result<RateHistory>> _historyFromCache({
    required Currency currency,
    required int days,
    required Failure fallbackFailure,
  }) async {
    final cached = await _local.readHistory(currency.code);
    if (cached.isEmpty) return Err(fallbackFailure);

    final history = _buildHistory(
      currency: currency,
      snapshots: cached,
      days: days,
    );
    if (history.isEmpty) return Err(fallbackFailure);
    return Ok(history);
  }

  // ── Cache writes ──────────────────────────────────────────────────────────

  /// Caching is best-effort. A full disk must never turn a successful fetch
  /// into a user-visible error.
  Future<void> _safeCache({
    required RatesSnapshotModel latest,
    RatesSnapshotModel? previous,
  }) async {
    try {
      await _local.cacheSnapshots(
        latest: latest,
        previous: previous,
        cachedAt: _now(),
      );
    } on Object {
      return;
    }
  }

  Future<void> _safeCacheHistory({
    required Currency currency,
    required List<RatesSnapshotModel> snapshots,
  }) async {
    try {
      await _local.cacheHistory(
        currencyCode: currency.code,
        snapshots: snapshots,
      );
    } on Object {
      return;
    }
  }
}
