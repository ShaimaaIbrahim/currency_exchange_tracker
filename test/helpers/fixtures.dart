import 'package:currency_exchange_tracker/features/currency/data/models/rates_snapshot_model.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency_rate.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rates_board.dart';

/// Shared, deliberately unrealistic-but-round test data.
///
/// Quotes are chosen so the inverted rates come out exact (`0.02 -> 50.0`),
/// which keeps assertions readable without `closeTo` everywhere.
abstract final class Fixtures {
  /// Fixed "now" so tests never depend on the day they run.
  static final DateTime now = DateTime(2026, 9, 9, 14, 30);
  static final DateTime today = DateTime(2026, 9, 9);
  static final DateTime yesterday = DateTime(2026, 9, 8);

  /// 1 EGP = 0.02 USD, i.e. 1 USD = 50 EGP.
  static RatesSnapshotModel latestSnapshot({DateTime? date}) =>
      RatesSnapshotModel(
        date: date ?? today,
        quotes: const {
          'usd': 0.02,
          'eur': 0.0125,
          'gbp': 0.01,
          'sar': 0.08,
          'jpy': 2.0,
          'aed': 0.07,
        },
      );

  /// Yesterday: 1 USD = 40 EGP. Today's 50 is therefore a **weaker** pound.
  static RatesSnapshotModel previousSnapshot({DateTime? date}) =>
      RatesSnapshotModel(
        date: date ?? yesterday,
        quotes: const {
          'usd': 0.025,
          'eur': 0.0125,
          'gbp': 0.0125,
          'sar': 0.08,
          'jpy': 2.5,
        },
      );

  static Map<String, dynamic> latestJson({String date = '2026-09-09'}) => {
    'date': date,
    'egp': {'usd': 0.02, 'eur': 0.0125, 'gbp': 0.01, 'sar': 0.08, 'jpy': 2.0},
  };

  static CurrencyRate usdRate({
    double egpPerUnit = 50,
    double? previousEgpPerUnit = 40,
  }) => CurrencyRate(
    currency: Currency.usd,
    egpPerUnit: egpPerUnit,
    asOf: today,
    previousEgpPerUnit: previousEgpPerUnit,
    previousAsOf: previousEgpPerUnit == null ? null : yesterday,
  );

  static RatesBoard board({
    RatesSource source = RatesSource.network,
    List<CurrencyRate>? rates,
    DateTime? retrievedAt,
  }) => RatesBoard(
    rates: rates ?? [usdRate()],
    retrievedAt: retrievedAt ?? now,
    publishedAt: today,
    source: source,
  );

  static RateHistory history({
    Currency currency = Currency.usd,
    int pointCount = 7,
    int requestedDays = 7,
  }) => RateHistory(
    currency: currency,
    points: List<RatePoint>.generate(
      pointCount,
      (index) => RatePoint(
        date: today.subtract(Duration(days: pointCount - 1 - index)),
        egpPerUnit: 48 + index * 0.5,
      ),
    ),
    requestedDays: requestedDays,
  );
}
