/// All user-facing copy, in one place.
///
/// Widgets, pages and failures should read labels from here rather than
/// inlining text. Parameterised helpers keep interpolation consistent.
abstract final class AppStrings {
  // ── App ──────────────────────────────────────────────────────────────────

  static const String appTitle = 'Currency Exchange Tracker';

  // ── Rates board ──────────────────────────────────────────────────────────

  static const String ratesTitle = 'Exchange Rates';
  static const String ratesSubtitle = 'Against the Egyptian Pound';
  static const String refreshRatesTooltip = 'Refresh rates';
  static const String retry = 'Retry';
  static const String refresh = 'Refresh';
  static const String tryAgain = 'Try again';

  static String updatedRelative(String relative) => 'Updated $relative';

  static String ratesForDateUpdated(String date, String relative) =>
      'Rates for $date · updated $relative';

  // ── Empty / not found ────────────────────────────────────────────────────

  static const String emptyRatesTitle = 'No rates to show';
  static const String emptyRatesMessage =
      'The exchange-rate feed returned no rates for the currencies '
      'we track. Pull down to try again.';

  static const String notFoundAppBar = 'Not found';
  static const String pageNotFoundTitle = 'Page not found';
  static const String backToRates = 'Back to rates';

  static String untrackedCurrency(String code) =>
      'We do not track "$code" yet.';

  static String unknownRoute(String uri) => 'We could not find "$uri".';

  // ── Offline / cache ──────────────────────────────────────────────────────

  static const String offlineChip = 'Offline';
  static const String deviceOfflineLabel = 'Device is offline';
  static const String offlineShowingSaved = 'Offline — showing saved rates';
  static const String showingSavedRates = 'Showing saved rates';

  static String lastUpdatedPrefix(String relative) => 'Last updated $relative';

  static const String staleOfflineSuffix =
      "These rates may be well out of date — we'll refresh as "
      'soon as you reconnect.';

  static const String freshOfflineSuffix =
      "We'll refresh automatically when you reconnect.";

  static const String onlineCacheSuffix =
      "We couldn't reach the service, so these are the last "
      'rates we saved.';

  static String offlineSubtitle({
    required String relative,
    required bool isOffline,
    required bool isStale,
  }) {
    final prefix = lastUpdatedPrefix(relative);
    if (!isOffline) return '$prefix. $onlineCacheSuffix';
    return isStale
        ? '$prefix. $staleOfflineSuffix'
        : '$prefix. $freshOfflineSuffix';
  }

  // ── Rate card / change ───────────────────────────────────────────────────

  static const String noChangeData = 'No change data';
  static const String egpStronger = 'Egyptian Pound stronger';
  static const String egpWeaker = 'Egyptian Pound weaker';
  static const String unchanged = 'Unchanged';

  static String trendByPercent(String direction, double percent) =>
      '$direction by ${percent.abs().toStringAsFixed(2)} percent';

  // ── Detail summary ───────────────────────────────────────────────────────

  static const String currentRate = 'Current rate';
  static const String lastUpdated = 'Last updated';
  static const String comparedWith = 'Compared with';
  static const String vsPreviousClose = 'vs. previous close';
  static const String vsYesterday = 'vs. yesterday';

  static String vsDaysAgo(int days) => 'vs. $days days ago';

  static String changeWindowLabel({
    required DateTime asOf,
    DateTime? previous,
  }) {
    if (previous == null) return vsPreviousClose;
    final days = asOf.difference(previous).inDays;
    if (days <= 1) return vsYesterday;
    return vsDaysAgo(days);
  }

  static const String rateUnavailableTitle = 'Rate unavailable';
  static const String loadRates = 'Load rates';

  static String rateUnavailableMessage(String code) =>
      'We do not have a current $code rate yet. The chart below still works.';

  // ── History chart ────────────────────────────────────────────────────────

  static const String reloadChartTooltip = 'Reload chart';
  static const String last7Days = 'Last 7 days';

  static String egpPerUnit(String code) => 'EGP per 1 $code';

  static const String noHistoryTitle = 'No history yet';
  static const String noHistoryMessage =
      'The feed has not published rates for this currency over the '
      'last 7 days.';

  static const String notEnoughHistoryTitle = 'Not enough history';

  static String notEnoughHistoryMessage(String code) =>
      'Only one day of $code data is available, which is not enough '
      'to draw a trend.';

  static String partialHistoryNote({
    required int shown,
    required int requested,
  }) =>
      'Showing $shown of the last $requested days — the feed did not '
      'publish rates on the missing dates.';

  static String chartTooltipRate(String formattedRate) => '$formattedRate EGP';

  static String chartSemantics({
    required String currencyName,
    required int days,
    required String fromRate,
    required String fromDate,
    required String toRate,
    required String toDate,
  }) =>
      '$currencyName rate chart. $days days. '
      'From $fromRate EGP on $fromDate to $toRate EGP on $toDate.';

  // ── Failure titles (message views) ───────────────────────────────────────

  static const String failureOfflineTitle = "You're offline";
  static const String failureTimeoutTitle = 'Connection timed out';
  static const String failureConnectionTitle = "Can't reach the service";
  static const String failureServerTitle = 'Service unavailable';
  static const String failureNoDataTitle = 'No data available';
  static const String failureCacheTitle = 'Saved data unavailable';
  static const String failureParsingTitle = 'Unexpected response';
  static const String failureGenericTitle = 'Something went wrong';

  // ── Failure messages ─────────────────────────────────────────────────────

  static const String failureOfflineMessage =
      'You appear to be offline and no saved rates are available yet. '
      'Connect to the internet and try again.';

  static const String failureTimeoutMessage =
      'The connection is taking too long. Please try again.';

  static const String failureConnectionMessage =
      'We could not reach the exchange-rate service. '
      'Check your connection and try again.';

  static const String failureServerMessage =
      'The exchange-rate service is temporarily unavailable. '
      'Please try again in a moment.';

  static const String failureRequestMessage =
      'We could not load the exchange rates for this request.';

  static const String failureParsingMessage =
      'We received an unexpected response and could not read the '
      'exchange rates.';

  static const String failureNoDataMessage =
      'No exchange-rate data has been published for this period yet.';

  static const String failureCacheMessage =
      'We could not read the rates saved on this device.';

  static const String failureUnexpectedMessage =
      'Something went wrong. Please try again.';

  static const String requestCancelled = 'The request was cancelled.';

  static const String historyUnavailable =
      'No exchange-rate history is available for the last '
      '7 days. Please try again later.';

  static String historyMissingCurrency(String code) =>
      'The feed did not publish $code rates for this period.';

  // ── Relative time ────────────────────────────────────────────────────────

  static const String justNow = 'just now';

  static String minutesAgo(int count) =>
      '$count ${_plural(count, 'minute')} ago';

  static String hoursAgo(int count) => '$count ${_plural(count, 'hour')} ago';

  static String daysAgo(int count) => '$count ${_plural(count, 'day')} ago';

  static String onDate(String date) => 'on $date';

  static String _plural(int count, String word) =>
      count == 1 ? word : '${word}s';
}
