import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:equatable/equatable.dart';

/// A single point on the detail screen's line chart.
class RatePoint extends Equatable {
  const RatePoint({required this.date, required this.egpPerUnit});

  final DateTime date;

  /// EGP per one unit of the currency, already inverted for display.
  final double egpPerUnit;

  @override
  List<Object?> get props => [date, egpPerUnit];
}

/// The historical series for one currency pair.
///
/// [points] is guaranteed sorted oldest-first, and may be **shorter** than the
/// requested window: the feed skips days, and a partial series is far more
/// useful than an error. [requestedDays] records what was asked for so the UI
/// can say "5 of the last 7 days" honestly.
class RateHistory extends Equatable {
  const RateHistory({
    required this.currency,
    required this.points,
    required this.requestedDays,
  });

  final Currency currency;
  final List<RatePoint> points;
  final int requestedDays;

  bool get isEmpty => points.isEmpty;

  /// True when at least one day in the window returned no data.
  bool get isPartial => points.length < requestedDays;

  /// A chart needs two points to draw a line; one point can only be a dot.
  bool get isPlottable => points.length >= 2;

  double get minRate =>
      points.map((point) => point.egpPerUnit).reduce((a, b) => a < b ? a : b);

  double get maxRate =>
      points.map((point) => point.egpPerUnit).reduce((a, b) => a > b ? a : b);

  RatePoint get first => points.first;

  RatePoint get last => points.last;

  /// Net movement across the whole window, in EGP per unit.
  double get windowChange => last.egpPerUnit - first.egpPerUnit;

  @override
  List<Object?> get props => [currency, points, requestedDays];
}
