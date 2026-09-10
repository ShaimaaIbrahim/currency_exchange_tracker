import 'package:currency_exchange_tracker/core/constants/app_constants.dart';
import 'package:currency_exchange_tracker/core/extensions/date_time_x.dart';

/// URL builder for the currency-api feed.
///
/// The feed encodes the date in the **host**, not the path
/// (`https://2026-06-01.currency-api.pages.dev/...`), so URLs are built here
/// as absolute strings instead of relying on a Dio `baseUrl`.
abstract final class ApiEndpoints {
  static const String _scheme = 'https';
  static const String _host = 'currency-api.pages.dev';
  static const String _latestSubdomain = 'latest';

  /// Today's rates for [base].
  static String latest({String base = AppConstants.baseCurrencyCode}) =>
      _build(_latestSubdomain, base);

  /// Rates published on [date] for [base].
  static String historical(
    DateTime date, {
    String base = AppConstants.baseCurrencyCode,
  }) => _build(date.toApiDate(), base);

  static String _build(String subdomain, String base) =>
      '$_scheme://$subdomain.$_host/v1/currencies/${base.toLowerCase()}.json';
}
