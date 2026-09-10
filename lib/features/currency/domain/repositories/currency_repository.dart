import 'package:currency_exchange_tracker/core/utils/result.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rates_board.dart';

/// The domain's view of exchange-rate storage.
///
/// Deliberately says nothing about HTTP, JSON or `SharedPreferences`: the
/// domain asks for rates and gets either rates or a `Failure`. Whether they
/// arrived over the wire or out of the cache is expressed in the returned
/// [RatesBoard.source], not in the method name — callers that do not care
/// about provenance never have to branch on it.
abstract interface class CurrencyRepository {
  /// The current board for all tracked currencies, including day-over-day
  /// change.
  ///
  /// When the device is offline this falls back to cached data and marks it
  /// [RatesSource.cache]. It only fails when there is neither network nor
  /// usable cache.
  Future<Result<RatesBoard>> getRatesBoard({bool forceRefresh = false});

  /// The trailing [days]-day series for one [currency], oldest point first.
  Future<Result<RateHistory>> getRateHistory({
    required Currency currency,
    int days,
  });

  /// Emits `true`/`false` as the device gains and loses connectivity.
  Stream<bool> watchConnectivity();

  /// Current connectivity, for a one-off check on start-up.
  Future<bool> isConnected();
}
