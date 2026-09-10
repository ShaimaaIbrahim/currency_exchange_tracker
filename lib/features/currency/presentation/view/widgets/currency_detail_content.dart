import 'package:currency_exchange_tracker/core/responsive/responsive_context.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/rate_history_section.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/rate_summary_section.dart';
import 'package:flutter/material.dart';

/// Summary + 7-day chart. Side-by-side on wide screens, stacked otherwise.
class CurrencyDetailContent extends StatelessWidget {
  const CurrencyDetailContent({required this.currency, super.key});

  final Currency currency;

  @override
  Widget build(BuildContext context) {
    // Side-by-side on wide screens: the summary is a tall narrow block and the
    // chart is a wide short one, so stacking them wastes a lot of screen.
    final isSideBySide = context.isAtLeastExpanded;

    final summary = RateSummarySection(currency: currency);
    final chart = RateHistorySection(currency: currency);

    if (!isSideBySide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [summary, const Gap(AppSpacing.lg), chart],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: summary),
        const Gap.horizontal(AppSpacing.lg),
        Expanded(flex: 6, child: chart),
      ],
    );
  }
}
