import 'package:currency_exchange_tracker/core/responsive/responsive_context.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/core/utils/rate_formatter.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency_rate.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/currency_avatar.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/rate_change_badge.dart';
import 'package:flutter/material.dart';

/// One row of the exchange-rate board.
///
/// The layout switches from a single row to a stacked column when the tile is
/// narrow *or* the user has scaled text up, because "rate on the right, name on
/// the left" stops working as soon as either side needs more than half the
/// width. That check uses the tile's own constraints, so the same widget is
/// correct in a list, a two-column grid or a detail pane.
class RateCard extends StatelessWidget {
  const RateCard({required this.rate, required this.onTap, super.key});

  final CurrencyRate rate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(
            context.responsive<double>(
              compact: AppSpacing.md,
              medium: AppSpacing.lg,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final shouldStack = constraints.maxWidth < 340 || textScale > 1.3;

              final identity = Row(
                children: [
                  CurrencyAvatar(
                    currency: rate.currency,
                    size: context.responsive<double>(compact: 42, medium: 48),
                  ),
                  const Gap.horizontal(AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rate.currency.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          rate.currency.pairLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final figures = Column(
                crossAxisAlignment: shouldStack
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: shouldStack
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Text(
                      RateFormatter.rate(rate.egpPerUnit),
                      maxLines: 1,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        // Tabular figures stop the numbers jittering horizontally
                        // when a refresh changes a digit's width.
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      semanticsLabel: RateFormatter.pairSentence(
                        rate.currency,
                        rate.egpPerUnit,
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.xs),
                  RateChangeBadge(rate: rate, isCompact: true),
                ],
              );

              if (shouldStack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [identity, const Gap(AppSpacing.md), figures],
                );
              }

              return Row(
                children: [
                  Expanded(child: identity),
                  const Gap.horizontal(AppSpacing.md),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.42,
                    ),
                    child: figures,
                  ),
                  const Gap.horizontal(AppSpacing.xs),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Skeleton twin of [RateCard]. Its height is derived from the same spacing
/// constants, so the shimmer occupies the space the real row will — no layout
/// jump when data lands.
class RateCardSkeleton extends StatelessWidget {
  const RateCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final avatarSize = context.responsive<double>(compact: 42, medium: 48);
    final padding = context.responsive<double>(
      compact: AppSpacing.md,
      medium: AppSpacing.lg,
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: SizedBox(
          height: avatarSize,
          child: Row(
            children: [
              _Box.circle(avatarSize),
              const Gap.horizontal(AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Box(width: 120, height: 15),
                    Gap(AppSpacing.sm),
                    _Box(width: 64, height: 11),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Box(width: 76, height: 18),
                  Gap(AppSpacing.sm),
                  _Box(width: 52, height: 11),
                ],
              ),
              const Gap.horizontal(AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.width, required this.height}) : _isCircle = false;

  const _Box.circle(double size)
    : width = size,
      height = size,
      _isCircle = true;

  final double width;
  final double height;
  final bool _isCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: _isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: _isCircle ? null : BorderRadius.circular(AppSpacing.xs),
      ),
    );
  }
}
