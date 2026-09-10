/// Which way the Egyptian Pound moved between two snapshots.
///
/// Named after the **EGP**, not after the quoted number, because the spec's
/// colour rule is about the pound: green when EGP strengthens, red when it
/// weakens. Since rates are quoted as "EGP per 1 foreign unit", a *falling*
/// number means the pound got stronger — the sign is inverted relative to the
/// usual stock-ticker intuition, and encoding it in a named type stops that
/// from being re-derived (and re-broken) at every call site.
enum RateTrend {
  /// Fewer EGP now buy one foreign unit. Shown in green.
  egpStronger,

  /// More EGP are now needed for one foreign unit. Shown in red.
  egpWeaker,

  /// No measurable movement, or no comparison snapshot available.
  unchanged;

  bool get isStronger => this == RateTrend.egpStronger;

  bool get isWeaker => this == RateTrend.egpWeaker;

  bool get isUnchanged => this == RateTrend.unchanged;

  /// Classifies a change in "EGP per foreign unit".
  ///
  /// [epsilon] guards against float noise being rendered as a real move; the
  /// feed publishes ~8 significant digits, so anything under a hundred-
  /// thousandth of a piastre is not a price change.
  static RateTrend fromEgpPerUnitDelta(double delta, {double epsilon = 1e-6}) {
    if (delta.abs() < epsilon) return RateTrend.unchanged;
    return delta < 0 ? RateTrend.egpStronger : RateTrend.egpWeaker;
  }
}
