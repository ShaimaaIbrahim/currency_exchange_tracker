import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rate_trend.dart';
import 'package:equatable/equatable.dart';

/// One row of the exchange-rate board: a currency plus how it moved today.
///
/// All rates here are already **inverted** into the display orientation —
/// "how many EGP buy one unit of [currency]". The API publishes the opposite
/// direction (`egp.usd = 0.019` means 1 EGP = 0.019 USD), and that inversion
/// happens once, in [CurrencyRate.fromEgpQuotes], so no other layer has to
/// remember which way round the number is.
class CurrencyRate extends Equatable {
  const CurrencyRate({
    required this.currency,
    required this.egpPerUnit,
    required this.asOf,
    this.previousEgpPerUnit,
    this.previousAsOf,
  });

  /// Builds a rate from the API's raw `egp.<code>` quotes.
  ///
  /// [unitsPerEgp] is today's quote and [previousUnitsPerEgp] yesterday's,
  /// both in the API's native "foreign units per 1 EGP" direction.
  factory CurrencyRate.fromEgpQuotes({
    required Currency currency,
    required double unitsPerEgp,
    required DateTime asOf,
    double? previousUnitsPerEgp,
    DateTime? previousAsOf,
  }) {
    return CurrencyRate(
      currency: currency,
      egpPerUnit: _invert(unitsPerEgp),
      asOf: asOf,
      previousEgpPerUnit: previousUnitsPerEgp == null
          ? null
          : _invert(previousUnitsPerEgp),
      previousAsOf: previousAsOf,
    );
  }

  final Currency currency;

  /// EGP needed to buy one unit of [currency], e.g. `52.01` for USD.
  final double egpPerUnit;

  /// Date the [egpPerUnit] quote was published.
  final DateTime asOf;

  /// The comparison quote, or `null` when no previous snapshot could be
  /// fetched. The UI must then hide the change indicator rather than show a
  /// misleading `0.00`.
  final double? previousEgpPerUnit;

  /// Date [previousEgpPerUnit] was published. Not always "yesterday": the feed
  /// skips days, so the repository walks back until it finds one.
  final DateTime? previousAsOf;

  /// Whether a day-over-day comparison is available at all.
  bool get hasChange => previousEgpPerUnit != null;

  /// Change in EGP per unit. Negative means the pound strengthened.
  double? get absoluteChange {
    final previous = previousEgpPerUnit;
    if (previous == null) return null;
    return egpPerUnit - previous;
  }

  /// Change as a percentage of the previous quote. Negative means the pound
  /// strengthened. `null` when there is no previous quote, or when it was zero
  /// (which would make the percentage undefined rather than infinite).
  double? get percentageChange {
    final previous = previousEgpPerUnit;
    final absolute = absoluteChange;
    if (previous == null || absolute == null || previous == 0) return null;
    return (absolute / previous) * 100;
  }

  /// Colour/semantics driver for the change indicator.
  RateTrend get trend {
    final absolute = absoluteChange;
    if (absolute == null) return RateTrend.unchanged;
    return RateTrend.fromEgpPerUnitDelta(absolute);
  }

  /// The API quotes `foreign per 1 EGP`; the product displays
  /// `EGP per 1 foreign`. A non-positive quote would mean a corrupt payload,
  /// so it is surfaced as `0` rather than `Infinity`/`NaN` leaking into the
  /// chart and formatters.
  static double _invert(double unitsPerEgp) {
    if (unitsPerEgp <= 0 || !unitsPerEgp.isFinite) return 0;
    return 1 / unitsPerEgp;
  }

  CurrencyRate copyWith({double? previousEgpPerUnit, DateTime? previousAsOf}) {
    return CurrencyRate(
      currency: currency,
      egpPerUnit: egpPerUnit,
      asOf: asOf,
      previousEgpPerUnit: previousEgpPerUnit ?? this.previousEgpPerUnit,
      previousAsOf: previousAsOf ?? this.previousAsOf,
    );
  }

  @override
  List<Object?> get props => [
    currency,
    egpPerUnit,
    asOf,
    previousEgpPerUnit,
    previousAsOf,
  ];
}
