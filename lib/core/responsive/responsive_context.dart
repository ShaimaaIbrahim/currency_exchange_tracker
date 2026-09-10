import 'package:currency_exchange_tracker/core/responsive/app_breakpoints.dart';
import 'package:flutter/widgets.dart';

/// Ergonomic access to layout information from a [BuildContext].
///
/// Everything here reads `MediaQuery`, so widgets rebuild automatically when
/// the window is resized, the device rotates, or the app enters split-screen.
extension ResponsiveContext on BuildContext {
  MediaQueryData get _mq => MediaQuery.of(this);

  /// Logical width of the window.
  double get screenWidth => _mq.size.width;

  /// Logical height of the window.
  double get screenHeight => _mq.size.height;

  /// The current size class.
  WindowSize get windowSize => AppBreakpoints.sizeForWidth(screenWidth);

  bool get isCompact => windowSize.isCompact;

  bool get isAtLeastMedium => windowSize.isAtLeastMedium;

  bool get isAtLeastExpanded => windowSize.isAtLeastExpanded;

  bool get isLandscape => _mq.orientation == Orientation.landscape;

  /// Viewport is too short for decorative vertical spacing (landscape phone,
  /// keyboard open, tiny desktop window).
  bool get isShortViewport => screenHeight < AppBreakpoints.shortViewportHeight;

  /// Safe-area insets, e.g. notch and home indicator.
  EdgeInsets get viewPadding => _mq.viewPadding;

  /// Picks a value per size class, falling back to the next narrower value that
  /// was supplied. Only [compact] is required, so call sites stay short:
  ///
  /// ```dart
  /// final columns = context.responsive(compact: 1, medium: 2, expanded: 3);
  /// ```
  T responsive<T>({required T compact, T? medium, T? expanded, T? large}) =>
      switch (windowSize) {
        WindowSize.compact => compact,
        WindowSize.medium => medium ?? compact,
        WindowSize.expanded => expanded ?? medium ?? compact,
        WindowSize.large => large ?? expanded ?? medium ?? compact,
      };

  /// Horizontal page padding that grows with available width.
  double get pagePadding =>
      responsive<double>(compact: 16, medium: 24, expanded: 32);

  /// Number of columns a card grid should use.
  int get gridColumns => responsive<int>(compact: 1, medium: 2, expanded: 3);
}
