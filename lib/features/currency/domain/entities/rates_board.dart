import 'package:currency_exchange_tracker/core/constants/app_constants.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency_rate.dart';
import 'package:equatable/equatable.dart';

/// Where a [RatesBoard] came from. Drives the "showing saved data" banner.
enum RatesSource {
  /// Freshly fetched from the network.
  network,

  /// Read from the on-device cache because the network was unavailable.
  cache,
}

/// The full set of tracked rates as of one moment, plus its provenance.
class RatesBoard extends Equatable {
  const RatesBoard({
    required this.rates,
    required this.retrievedAt,
    required this.source,
    this.publishedAt,
  });

  /// One entry per tracked currency, in [Currency.values] order.
  final List<CurrencyRate> rates;

  /// When this data was obtained — the fetch time for [RatesSource.network],
  /// the original fetch time for [RatesSource.cache]. This is what the offline
  /// indicator shows, because the user cares about staleness, not publication.
  final DateTime retrievedAt;

  /// The date the upstream feed stamped on the rates.
  final DateTime? publishedAt;

  final RatesSource source;

  bool get isFromCache => source == RatesSource.cache;

  bool get isEmpty => rates.isEmpty;

  /// Cached data past [AppConstants.cacheStaleAfter] is still shown, but the
  /// banner escalates its wording.
  bool isStale({DateTime? now}) =>
      (now ?? DateTime.now()).difference(retrievedAt) >
      AppConstants.cacheStaleAfter;

  CurrencyRate? rateFor(Currency currency) {
    for (final rate in rates) {
      if (rate.currency == currency) return rate;
    }
    return null;
  }

  RatesBoard copyWith({
    List<CurrencyRate>? rates,
    DateTime? retrievedAt,
    DateTime? publishedAt,
    RatesSource? source,
  }) {
    return RatesBoard(
      rates: rates ?? this.rates,
      retrievedAt: retrievedAt ?? this.retrievedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      source: source ?? this.source,
    );
  }

  @override
  List<Object?> get props => [rates, retrievedAt, publishedAt, source];
}
