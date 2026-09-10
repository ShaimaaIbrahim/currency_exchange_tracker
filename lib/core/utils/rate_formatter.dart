import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:intl/intl.dart';

/// Formats rates and deltas for display.
///
/// The awkward part is precision: `1 USD = 52.01 EGP` wants two decimals, but
/// `1 JPY = 0.33 EGP` would lose all meaning at two decimals if the rate were
/// smaller still. So decimals scale with magnitude rather than being fixed.
abstract final class RateFormatter {
  /// `52.0138` → `'52.01'`, `0.0034` → `'0.003400'`
  static String rate(double value) {
    return NumberFormat(_patternFor(value), 'en_US').format(value);
  }

  /// `1 USD = 52.01 EGP`
  static String pairSentence(Currency currency, double egpPerUnit) =>
      '1 ${currency.code} = ${rate(egpPerUnit)} ${Currency.baseCode}';

  /// Signed absolute change, e.g. `'+0.14'` / `'−0.14'`.
  ///
  /// Uses U+2212 MINUS SIGN rather than a hyphen so the glyph aligns with `+`
  /// at the same optical weight.
  static String signedChange(double value) {
    final formatted = NumberFormat(
      _patternFor(value),
      'en_US',
    ).format(value.abs());
    return '${_signOf(value)}$formatted';
  }

  /// `'+0.27%'` / `'−0.27%'`
  static String signedPercentage(double value) {
    final formatted = NumberFormat('0.00', 'en_US').format(value.abs());
    return '${_signOf(value)}$formatted%';
  }

  /// Compact y-axis label — full precision would not fit beside a chart.
  static String axisLabel(double value) {
    if (value >= 100) return NumberFormat('0', 'en_US').format(value);
    if (value >= 1) return NumberFormat('0.00', 'en_US').format(value);
    return NumberFormat('0.000', 'en_US').format(value);
  }

  static String _signOf(double value) {
    if (value == 0) return '';
    return value > 0 ? '+' : '\u2212';
  }

  /// More decimals for smaller numbers, so JPY stays as legible as GBP.
  static String _patternFor(double value) {
    final magnitude = value.abs();
    if (magnitude >= 100) return '0.00';
    if (magnitude >= 1) return '0.00';
    if (magnitude >= 0.01) return '0.0000';
    return '0.000000';
  }
}
