import 'package:currency_exchange_tracker/core/extensions/date_time_x.dart';
import 'package:currency_exchange_tracker/core/responsive/responsive_context.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/core/utils/rate_formatter.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency_rate.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/currency_avatar.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/rate_change_badge.dart';
import 'package:flutter/material.dart';

/// The detail screen's header: current rate, daily change, last-update date.
class RateSummaryCard extends StatelessWidget {
  const RateSummaryCard({required this.rate, super.key});

  final CurrencyRate rate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(
          context.responsive<double>(
            compact: AppSpacing.lg,
            medium: AppSpacing.xl,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CurrencyAvatar(currency: rate.currency, size: 40),
                const Gap.horizontal(AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rate.currency.displayName,
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
            ),
            const Gap(AppSpacing.xl),
            Text(
              'Current rate',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(AppSpacing.xs),
            // `FittedBox` down-scales rather than wrapping: a long rate at 200%
            // text scale must stay one line to remain scannable.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                RateFormatter.pairSentence(rate.currency, rate.egpPerUnit),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const Gap(AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                RateChangeBadge(rate: rate),
                Text(
                  _changeWindowLabel(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.lg),
            const Divider(),
            const Gap(AppSpacing.md),
            _MetaRow(
              icon: Icons.event_available_rounded,
              label: 'Last updated',
              value: rate.asOf.toMediumDate(),
            ),
            if (rate.previousAsOf case final previous?) ...[
              const Gap(AppSpacing.sm),
              _MetaRow(
                icon: Icons.history_rounded,
                label: 'Compared with',
                value: previous.toMediumDate(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The comparison snapshot is usually yesterday, but the feed skips days —
  /// so the label says what was actually compared instead of assuming.
  String _changeWindowLabel() {
    final previous = rate.previousAsOf;
    if (previous == null) return 'vs. previous close';
    final days = rate.asOf.difference(previous).inDays;
    if (days <= 1) return 'vs. yesterday';
    return 'vs. $days days ago';
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const Gap.horizontal(AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
