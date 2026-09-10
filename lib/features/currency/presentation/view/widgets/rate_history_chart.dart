import 'package:currency_exchange_tracker/core/constants/app_strings.dart';
import 'package:currency_exchange_tracker/core/extensions/date_time_x.dart';
import 'package:currency_exchange_tracker/core/responsive/responsive_context.dart';
import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/core/utils/rate_formatter.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rate_trend.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// The 7-day line chart.
///
/// Two things make this readable rather than merely correct:
/// * the y-axis is padded around the *actual* range instead of starting at
///   zero, because a 0.3% daily move on a 52 EGP rate is invisible on a
///   zero-based axis;
/// * x labels thin out as the chart narrows, so a phone shows every other day
///   rather than seven overlapping labels.
class RateHistoryChart extends StatelessWidget {
  const RateHistoryChart({required this.history, super.key});

  final RateHistory history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;

    // Line colour follows the same EGP-centric rule as the badges: the pound
    // strengthening over the window is green, even though the plotted line is
    // going down.
    final trend = RateTrend.fromEgpPerUnitDelta(history.windowChange);
    final lineColor = switch (trend) {
      RateTrend.egpStronger => semantic.gain,
      RateTrend.egpWeaker => semantic.loss,
      RateTrend.unchanged => theme.colorScheme.primary,
    };

    final spots = <FlSpot>[
      for (var i = 0; i < history.points.length; i++)
        FlSpot(i.toDouble(), history.points[i].egpPerUnit),
    ];

    final bounds = _AxisBounds.from(history);
    final labelEvery = _labelInterval(context, history.points.length);

    return Semantics(
      label: _semanticsSummary(),
      excludeSemantics: true,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (history.points.length - 1).toDouble(),
          minY: bounds.min,
          maxY: bounds.max,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: bounds.step,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outlineVariant,
              strokeWidth: 1,
              dashArray: const [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: bounds.step,
                reservedSize: context.responsive<double>(
                  compact: 52,
                  medium: 60,
                ),
                getTitlesWidget: (value, meta) {
                  // Skip the edge labels: they collide with the chart border.
                  if (value <= bounds.min || value >= bounds.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Text(
                      RateFormatter.axisLabel(value),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= history.points.length) {
                    return const SizedBox.shrink();
                  }
                  // Always keep the newest label; thin the rest.
                  final isLast = index == history.points.length - 1;
                  if (!isLast && index % labelEvery != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      history.points[index].date.toChartLabel(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.inverseSurface,
              tooltipBorderRadius: BorderRadius.circular(AppSpacing.sm),
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final point = history.points[spot.x.round()];
                return LineTooltipItem(
                  '${AppStrings.chartTooltipRate(RateFormatter.rate(point.egpPerUnit))}\n',
                  theme.textTheme.labelMedium!.copyWith(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    TextSpan(
                      text: point.date.toMediumDate(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onInverseSurface.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              // Above ~0.35 a curve through volatile points overshoots and
              // invents lows that never happened.
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                // Dots only when there is room; seven dots on a narrow phone
                // is noise.
                show: context.isAtLeastMedium || history.points.length <= 7,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: index == spots.length - 1 ? 5 : 3,
                      color: theme.colorScheme.surface,
                      strokeWidth: 2.5,
                      strokeColor: lineColor,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withValues(alpha: 0.28),
                    lineColor.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  /// How many x labels fit without overlapping, given the window width.
  static int _labelInterval(BuildContext context, int pointCount) {
    if (pointCount <= 4) return 1;
    final maxLabels = context.responsive<int>(
      compact: 4,
      medium: 7,
      expanded: 7,
    );
    return (pointCount / maxLabels).ceil().clamp(1, pointCount);
  }

  String _semanticsSummary() {
    final first = history.first;
    final last = history.last;
    return AppStrings.chartSemantics(
      currencyName: history.currency.displayName,
      days: history.points.length,
      fromRate: RateFormatter.rate(first.egpPerUnit),
      fromDate: first.date.toMediumDate(),
      toRate: RateFormatter.rate(last.egpPerUnit),
      toDate: last.date.toMediumDate(),
    );
  }
}

/// Y-axis window, padded so the line never touches the top or bottom edge.
class _AxisBounds {
  const _AxisBounds({required this.min, required this.max, required this.step});

  factory _AxisBounds.from(RateHistory history) {
    final low = history.minRate;
    final high = history.maxRate;
    final span = high - low;

    // A flat week would give a zero-height axis, so fabricate a small window
    // around the value instead of dividing by zero.
    final padding = span == 0
        ? (high.abs() * 0.01).clamp(0.0001, 1.0)
        : span * 0.18;

    final min = low - padding;
    final max = high + padding;
    return _AxisBounds(min: min < 0 ? 0 : min, max: max, step: (max - min) / 4);
  }

  final double min;
  final double max;
  final double step;
}
