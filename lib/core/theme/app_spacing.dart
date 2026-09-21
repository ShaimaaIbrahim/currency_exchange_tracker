import 'package:currency_exchange_tracker/core/responsive/responsive_context.dart';
import 'package:flutter/widgets.dart';

/// A 4dp spacing scale. Using named steps instead of magic numbers is what
/// makes vertical rhythm survive refactors.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// A vertical or horizontal gap sized from [AppSpacing].
///
/// `Gap` renders as a `SliverToBoxAdapter`-free plain box, so it is cheap and
/// works in any flex. On short viewports the vertical variant shrinks by 25%
/// rather than pushing content off-screen.
class Gap extends StatelessWidget {
  const Gap(this.size, {super.key}) : _axis = Axis.vertical;

  const Gap.horizontal(this.size, {super.key}) : _axis = Axis.horizontal;

  final double size;
  final Axis _axis;

  @override
  Widget build(BuildContext context) {
    if (_axis == Axis.horizontal) {
      return SizedBox(width: size);
    }
    final scale = context.isShortViewport ? 0.75 : 1.0;
    return SizedBox(height: size * scale);
  }
}
