import 'package:currency_exchange_tracker/core/constants/app_constants.dart';
import 'package:currency_exchange_tracker/core/error/exceptions.dart';
import 'package:currency_exchange_tracker/core/extensions/date_time_x.dart';
import 'package:equatable/equatable.dart';

/// One raw API payload: the publication date plus every quote in it.
///
/// The feed returns 200+ currencies per call. This model keeps the map as-is
/// (still in the API's "foreign units per 1 EGP" direction) and lets the
/// repository pick out the five the product tracks. Filtering here instead
/// would make the cached payload lossy if the tracked set ever grows.
///
/// Shape:
/// ```json
/// { "date": "2026-09-09", "egp": { "usd": 0.019227, "eur": 0.016523, ... } }
/// ```
class RatesSnapshotModel extends Equatable {
  const RatesSnapshotModel({required this.date, required this.quotes});

  factory RatesSnapshotModel.fromJson(
    Map<String, dynamic> json, {
    String base = AppConstants.baseCurrencyCode,
  }) {
    final rawDate = json['date'];
    final rawQuotes = json[base.toLowerCase()];

    if (rawDate is! String || rawQuotes is! Map) {
      throw const ParsingException();
    }

    final date = DateTime.tryParse(rawDate);
    if (date == null) throw const ParsingException();

    final quotes = <String, double>{};
    for (final entry in rawQuotes.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String) continue;
      // The feed occasionally emits integers and, for delisted tokens, nulls.
      final quote = switch (value) {
        final num number => number.toDouble(),
        final String text => double.tryParse(text),
        _ => null,
      };
      if (quote == null || !quote.isFinite) continue;
      quotes[key.toLowerCase()] = quote;
    }

    if (quotes.isEmpty) throw const ParsingException();

    return RatesSnapshotModel(date: date.dateOnly, quotes: quotes);
  }

  /// Restores a snapshot previously written by [toJson].
  factory RatesSnapshotModel.fromCacheJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    final rawQuotes = json['quotes'];
    if (rawDate is! String || rawQuotes is! Map) {
      throw const CacheException();
    }
    final date = DateTime.tryParse(rawDate);
    if (date == null) throw const CacheException();

    final quotes = <String, double>{};
    for (final entry in rawQuotes.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is String && value is num) {
        quotes[key.toLowerCase()] = value.toDouble();
      }
    }
    return RatesSnapshotModel(date: date, quotes: quotes);
  }

  /// Publication date, normalised to midnight.
  final DateTime date;

  /// `currencyCode -> units of that currency per 1 EGP`.
  final Map<String, double> quotes;

  /// Cache representation. Intentionally *not* the API shape: the cache is our
  /// own format and should not have to change if the API's does.
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'quotes': quotes,
  };

  /// The quote for [code], or `null` if the feed omitted it.
  double? quoteFor(String code) => quotes[code.toLowerCase()];

  @override
  List<Object?> get props => [date, quotes];
}
