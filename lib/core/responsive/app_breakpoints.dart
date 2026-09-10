/// Layout size classes, following Material 3 window size classes.
///
/// The app never branches on "is this an iPhone" or `Platform.isAndroid`; it
/// branches on how much *width* it was given. That keeps split-screen,
/// foldables, desktop windows and browser resizes correct for free.
enum WindowSize {
  /// Phones in portrait, small split-screen panes. `< 600dp`.
  compact,

  /// Large phones in landscape, small tablets. `600–1023dp`.
  medium,

  /// Tablets in landscape, small desktop windows. `1024–1439dp`.
  expanded,

  /// Wide desktop and TV. `>= 1440dp`.
  large;

  bool get isCompact => this == WindowSize.compact;

  bool get isMedium => this == WindowSize.medium;

  bool get isExpanded => this == WindowSize.expanded;

  bool get isLarge => this == WindowSize.large;

  /// True for anything wider than a phone — the usual "give me more columns"
  /// question.
  bool get isAtLeastMedium => index >= WindowSize.medium.index;

  bool get isAtLeastExpanded => index >= WindowSize.expanded.index;
}

/// Width thresholds and layout constants shared by the whole app.
abstract final class AppBreakpoints {
  /// Upper bound (exclusive) of [WindowSize.compact].
  static const double compact = 600;

  /// Upper bound (exclusive) of [WindowSize.medium].
  static const double medium = 1024;

  /// Upper bound (exclusive) of [WindowSize.expanded].
  static const double expanded = 1440;

  /// Widest a single readable content column is ever allowed to get.
  ///
  /// Without this, list rows on a 27" monitor stretch to 2000dp and the eye
  /// cannot track a row from label to value.
  static const double maxContentWidth = 720;

  /// Same idea, for content that benefits from more room (charts, grids).
  static const double maxWideContentWidth = 1080;

  /// Smallest square a touch target may occupy, per WCAG 2.5.5 / Material.
  static const double minTouchTarget = 48;

  /// Below this height (e.g. landscape phone, software keyboard open) we drop
  /// decorative vertical space rather than let content overflow.
  static const double shortViewportHeight = 480;

  static WindowSize sizeForWidth(double width) {
    if (width < compact) return WindowSize.compact;
    if (width < medium) return WindowSize.medium;
    if (width < expanded) return WindowSize.expanded;
    return WindowSize.large;
  }
}
