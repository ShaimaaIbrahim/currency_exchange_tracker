import 'package:currency_exchange_tracker/core/constants/app_strings.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/core/widgets/app_state_views.dart';
import 'package:currency_exchange_tracker/core/widgets/shimmer_box.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/exchange_rates/exchange_rates_bloc.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/rate_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Current rate for [currency], or a recoverable fallback if the board
/// has not loaded yet.
class RateSummarySection extends StatelessWidget {
  const RateSummarySection({required this.currency, super.key});

  final Currency currency;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExchangeRatesBloc, ExchangeRatesState>(
      buildWhen: (previous, current) =>
          previous.board?.rateFor(currency) != current.board?.rateFor(currency),
      builder: (context, state) {
        final rate = state.board?.rateFor(currency);

        // Reached by deep link before the board has loaded, or after a failed
        // first load. Both are recoverable, so offer the retry rather than an
        // empty card.
        if (rate == null) {
          return RateSummaryFallback(state: state, currency: currency);
        }
        return RateSummaryCard(rate: rate);
      },
    );
  }
}

class RateSummaryFallback extends StatelessWidget {
  const RateSummaryFallback({
    required this.state,
    required this.currency,
    super.key,
  });

  final ExchangeRatesState state;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading || state.isInitial) {
      return const RateSummaryCardSkeleton();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: AppMessageView(
          icon: Icons.info_outline_rounded,
          title: AppStrings.rateUnavailableTitle,
          message: AppStrings.rateUnavailableMessage(currency.code),
          actionLabel: AppStrings.loadRates,
          onAction: () => context.read<ExchangeRatesBloc>().add(
            const ExchangeRatesRefreshRequested(),
          ),
        ),
      ),
    );
  }
}

/// Skeleton twin of [RateSummaryCard].
class RateSummaryCardSkeleton extends StatelessWidget {
  const RateSummaryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ShimmerGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ShimmerBox.circle(size: 40),
                  const Gap.horizontal(AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 130, height: 15),
                      Gap(AppSpacing.sm),
                      ShimmerBox(width: 70, height: 11),
                    ],
                  ),
                ],
              ),
              const Gap(AppSpacing.xl),
              const ShimmerBox(width: 90, height: 11),
              const Gap(AppSpacing.sm),
              const ShimmerBox(width: 210, height: 26),
              const Gap(AppSpacing.md),
              const ShimmerBox(width: 160, height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
