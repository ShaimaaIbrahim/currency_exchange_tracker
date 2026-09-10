import 'package:currency_exchange_tracker/core/constants/app_strings.dart';
import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/core/utils/rate_formatter.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency_rate.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rate_trend.dart';
import 'package:flutter/material.dart';

/// The colour-coded daily-change chip.
///
/// Colour is never the only signal: the arrow icon, the explicit `+`/`−` sign
/// and the semantics label all carry the same information, so the chip still
/// works for colour-blind users and screen readers.
class RateChangeBadge extends StatelessWidget {
  const RateChangeBadge({
    required this.rate,
    this.showAbsolute = true,
    this.isCompact = false,
    super.key,
  });

  final CurrencyRate rate;

  /// Whether to include the absolute EGP delta next to the percentage.
  final bool showAbsolute;

  /// Drops the background and shrinks the type, for dense list rows.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final absolute = rate.absoluteChange;
    final percentage = rate.percentageChange;

    if (absolute == null) {
      return Text(
        AppStrings.noChangeData,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final trend = rate.trend;
    final color = _colorFor(context, trend);
    final label = _label(absolute, percentage);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_iconFor(trend), size: isCompact ? 14 : 16, color: color),
        const Gap.horizontal(AppSpacing.xxs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (isCompact
                        ? theme.textTheme.labelMedium
                        : theme.textTheme.labelLarge)
                    ?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
          ),
        ),
      ],
    );

    return Semantics(
      label: _semanticsLabel(trend, percentage),
      excludeSemantics: true,
      child: isCompact
          ? content
          : DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: content,
              ),
            ),
    );
  }

  String _label(double absolute, double? percentage) {
    final percentagePart = percentage == null
        ? null
        : RateFormatter.signedPercentage(percentage);
    if (!showAbsolute) {
      return percentagePart ?? RateFormatter.signedChange(absolute);
    }

    final absolutePart = RateFormatter.signedChange(absolute);
    if (percentagePart == null) return absolutePart;
    return '$absolutePart  ($percentagePart)';
  }

  /// Green when the pound strengthened, red when it weakened — the arrow
  /// points the same way as the pound's fortunes, not the number's.
  static IconData _iconFor(RateTrend trend) => switch (trend) {
    RateTrend.egpStronger => Icons.arrow_upward_rounded,
    RateTrend.egpWeaker => Icons.arrow_downward_rounded,
    RateTrend.unchanged => Icons.remove_rounded,
  };

  static Color _colorFor(BuildContext context, RateTrend trend) {
    final colors = context.semanticColors;
    return switch (trend) {
      RateTrend.egpStronger => colors.gain,
      RateTrend.egpWeaker => colors.loss,
      RateTrend.unchanged => colors.flat,
    };
  }

  String _semanticsLabel(RateTrend trend, double? percentage) {
    final direction = switch (trend) {
      RateTrend.egpStronger => AppStrings.egpStronger,
      RateTrend.egpWeaker => AppStrings.egpWeaker,
      RateTrend.unchanged => AppStrings.unchanged,
    };
    if (percentage == null) return direction;
    return AppStrings.trendByPercent(direction, percentage);
  }
}
