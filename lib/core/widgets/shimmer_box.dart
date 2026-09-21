import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Wraps a subtree in a single shimmer sweep.
///
/// One `Shimmer` around a whole skeleton — rather than one per box — keeps the
/// highlight travelling across the group as a single wave, which reads as one
/// loading surface instead of several competing ones.
class ShimmerGroup extends StatelessWidget {
  const ShimmerGroup({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colors.surfaceContainerHighest,
      highlightColor: colors.surfaceContainerLow,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// A grey placeholder rectangle for use inside a [ShimmerGroup].
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    this.width,
    this.height = 14,
    this.radius = AppSpacing.xs,
    this.shape = BoxShape.rectangle,
    super.key,
  });

  /// Circular placeholder, for avatars and icons.
  const ShimmerBox.circle({required double size, super.key})
    : width = size,
      height = size,
      radius = 0,
      shape = BoxShape.circle;

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Any opaque colour works: `Shimmer` paints its gradient over it.
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(radius),
      ),
    );
  }
}
