import 'package:currency_exchange_tracker/core/responsive/app_breakpoints.dart';
import 'package:currency_exchange_tracker/core/responsive/responsive_context.dart';
import 'package:flutter/widgets.dart';

/// Centres content and caps its width so lines stay readable on wide windows.
///
/// Wrapping every page in this is the single highest-impact responsive rule in
/// the app: it is what stops a rate row from spanning 2000dp on a desktop.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.padding,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  /// Defaults to symmetric horizontal [ResponsiveContext.pagePadding].
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding:
              padding ?? EdgeInsets.symmetric(horizontal: context.pagePadding),
          child: child,
        ),
      ),
    );
  }
}

/// [ResponsiveCenter] for slivers, so pages can stay `CustomScrollView`-based
/// (needed for pull-to-refresh plus a collapsing header).
class ResponsiveSliverCenter extends StatelessWidget {
  const ResponsiveSliverCenter({
    required this.sliver,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    super.key,
  });

  final Widget sliver;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final horizontal = context.pagePadding;
    final overflow = context.screenWidth - maxWidth;
    // Distribute the leftover width evenly so the column sits centred, while
    // never dropping below the page's own gutter.
    final gutter = overflow > 0 ? overflow / 2 : 0.0;

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: gutter > horizontal ? gutter : horizontal,
      ),
      sliver: sliver,
    );
  }
}
