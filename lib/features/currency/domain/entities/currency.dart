/// The currencies this product tracks against EGP.
///
/// Modelled as an enum rather than discovered from the API because the set is
/// a fixed product decision. Keeping order, display names and response keys
/// together means adding a sixth currency is a one-line change.
enum Currency {
  usd(code: 'USD', displayName: 'US Dollar', symbol: r'$', flag: '🇺🇸'),
  eur(code: 'EUR', displayName: 'Euro', symbol: '€', flag: '🇪🇺'),
  gbp(code: 'GBP', displayName: 'British Pound', symbol: '£', flag: '🇬🇧'),
  sar(code: 'SAR', displayName: 'Saudi Riyal', symbol: 'SR', flag: '🇸🇦'),
  jpy(code: 'JPY', displayName: 'Japanese Yen', symbol: '¥', flag: '🇯🇵');

  const Currency({
    required this.code,
    required this.displayName,
    required this.symbol,
    required this.flag,
  });

  /// ISO-4217 code in upper case, e.g. `USD`.
  final String code;

  /// Human-readable name, e.g. `US Dollar`.
  final String displayName;

  /// Typographic symbol, e.g. `$`.
  final String symbol;

  /// Emoji flag — a lightweight icon with no asset or licensing cost.
  final String flag;

  /// The base currency every rate is quoted against.
  static const String baseCode = 'EGP';

  /// Key inside the API's `egp` map, e.g. `usd` for `egp.usd`.
  String get responseKey => code.toLowerCase();

  /// `USD/EGP`
  String get pairLabel => '$code/$baseCode';

  /// Resolves a code such as `usd` or `USD`; `null` when untracked.
  static Currency? fromCode(String code) {
    final normalised = code.toUpperCase();
    for (final currency in Currency.values) {
      if (currency.code == normalised) return currency;
    }
    return null;
  }
}
