import 'package:currency_exchange_tracker/core/constants/app_strings.dart';
import 'package:currency_exchange_tracker/core/extensions/date_time_x.dart';
import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rates_board.dart';
import 'package:flutter/material.dart';

/// The "you are looking at saved data" strip (Module 3).
///
/// It answers the two questions a user actually has when offline — *is this
/// live?* and *how old is it?* — so it always shows a relative timestamp
/// rather than just an offline icon.
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({required this.board, this.isOffline = true, super.key});

  final RatesBoard board;

  /// Whether the device is currently offline. A cached board shown while
  /// *online* means the fetch failed, which needs different wording.
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.semanticColors;
    final isStale = board.isStale();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.offlineBackground,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: colors.offlineForeground.withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + AppSpacing.xxs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isOffline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
            size: 18,
            color: colors.offlineForeground,
          ),
          const Gap.horizontal(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOffline
                      ? AppStrings.offlineShowingSaved
                      : AppStrings.showingSavedRates,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.offlineForeground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(AppSpacing.xxs),
                Text(
                  _subtitle(isStale),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.offlineForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(bool isStale) {
    return AppStrings.offlineSubtitle(
      relative: board.retrievedAt.toRelativeLabel(),
      isOffline: isOffline,
      isStale: isStale,
    );
  }
}

/// The always-present, one-line connectivity chip for the app bar.
class OfflineChip extends StatelessWidget {
  const OfflineChip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Semantics(
      label: AppStrings.deviceOfflineLabel,
      child: Container(
        decoration: BoxDecoration(
          color: colors.offlineBackground,
          borderRadius: BorderRadius.circular(AppSpacing.xxl),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 14,
              color: colors.offlineForeground,
            ),
            const Gap.horizontal(AppSpacing.xs),
            Text(
              AppStrings.offlineChip,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.offlineForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
