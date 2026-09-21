import 'package:flutter/widgets.dart';
import 'package:flutter_fluid/flutter_fluid.dart';

export 'package:flutter_fluid/flutter_fluid.dart'
    hide
        // The app already has a parent-constraint [ResponsiveBuilder] and a
        // [context.responsive] sized to Material 3 window classes. Importing
        // Fluid's copies of those names makes both calls ambiguous.
        ResponsiveBuilder,
        ResponsiveQueryExtension;

/// Shared [FluidInit] settings so the real app and widget tests scale alike.
///
/// [FluidInit] must wrap [WidgetsApp] / [MaterialApp], not sit inside it —
/// otherwise [Fluid] has no screen metrics before the first frame.
abstract final class AppFluid {
  /// Phone-sized design frame in dp. `16.r` is 16dp of this mock, not 16% of
  /// the window.
  static const Size designSize = Size(360, 690);

  static Widget init({required FluidInitBuilder builder, Widget? child}) {
    return FluidInit(
      designSize: designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      // Default resolver is width-only, which inflates type ~5× on a 1920dp
      // desktop. Radius follows min(width, height) so tablets/desktop stay
      // readable inside the existing 720/1080 content caps.
      fontSizeResolver: FontSizeResolvers.radius,
      builder: builder,
      child: child,
    );
  }
}
