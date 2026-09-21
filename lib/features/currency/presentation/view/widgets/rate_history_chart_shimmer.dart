import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/core/widgets/shimmer_box.dart';
import 'package:flutter/material.dart';

/// Loading state for the chart — a shimmering skeleton of a chart, not a
/// spinner.
///
/// The spec calls for shimmer specifically, and the reason it matters is
/// perceived layout stability: the skeleton reserves the axis gutter, the plot
/// area and the day labels at their real sizes, so when data arrives nothing
/// moves. A spinner would collapse to a dot and then jump.
class RateHistoryChartShimmer extends StatelessWidget {
  const RateHistoryChartShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerGroup(
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis labels.
                const Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 40),
                    ShimmerBox(width: 40),
                    ShimmerBox(width: 40),
                    ShimmerBox(width: 40),
                  ],
                ),
                const Gap.horizontal(AppSpacing.md),
                // Plot area: a jagged silhouette reads as "a chart is coming",
                // whereas a plain rectangle reads as "an image is coming".
                Expanded(
                  child: CustomPaint(
                    painter: _SkeletonLinePainter(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.md),
          // X-axis labels.
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List<Widget>.generate(
                4,
                (_) => const ShimmerBox(width: 30, height: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a fixed pseudo-random polyline plus its filled area.
///
/// The vertices are hard-coded rather than randomised so the skeleton does not
/// flicker into a different shape on every rebuild.
class _SkeletonLinePainter extends CustomPainter {
  const _SkeletonLinePainter({required this.color});

  final Color color;

  static const List<double> _heights = [
    0.62,
    0.45,
    0.55,
    0.30,
    0.40,
    0.22,
    0.32,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final stepX = size.width / (_heights.length - 1);
    final path = Path();

    for (var i = 0; i < _heights.length; i++) {
      final point = Offset(stepX * i, size.height * _heights[i]);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.45));
  }

  @override
  bool shouldRepaint(_SkeletonLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
