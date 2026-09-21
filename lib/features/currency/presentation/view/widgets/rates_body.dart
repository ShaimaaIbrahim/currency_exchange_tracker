import 'package:currency_exchange_tracker/core/constants/app_strings.dart';
import 'package:currency_exchange_tracker/core/extensions/date_time_x.dart';
import 'package:currency_exchange_tracker/core/responsive/app_breakpoints.dart';
import 'package:currency_exchange_tracker/core/responsive/responsive_context.dart';
import 'package:currency_exchange_tracker/core/responsive/responsive_scroll_view.dart';
import 'package:currency_exchange_tracker/core/router/app_router.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/core/widgets/app_state_views.dart';
import 'package:currency_exchange_tracker/core/widgets/shimmer_box.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency_rate.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/connectivity/connectivity_cubit.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/exchange_rates/exchange_rates_bloc.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/offline_notice.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/rate_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Loading, error, empty or populated board, as a sliver.
class RatesBody extends StatelessWidget {
  const RatesBody({required this.state, super.key});

  final ExchangeRatesState state;

  @override
  Widget build(BuildContext context) {
    if (state.isInitial || (state.isLoading && !state.hasRates)) {
      return const RatesSkeletonSliver();
    }

    if (state.hasFailure && state.failure != null) {
      return SliverFillMessage(
        child: AppMessageView.fromFailure(
          state.failure!,
          onRetry: () => context.read<ExchangeRatesBloc>().add(
            const ExchangeRatesRefreshRequested(),
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return SliverFillMessage(
        child: AppEmptyView(
          onRefresh: () => context.read<ExchangeRatesBloc>().add(
            const ExchangeRatesRefreshRequested(),
          ),
        ),
      );
    }

    final board = state.board!;

    return SliverMainAxisGroup(
      slivers: [
        if (board.isFromCache)
          ResponsiveSliverCenter(
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
                  builder: (context, connectivity) => OfflineNotice(
                    board: board,
                    isOffline: connectivity.isOffline,
                  ),
                ),
              ),
            ),
          ),
        ResponsiveSliverCenter(
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: BoardCaption(
                publishedAt: board.publishedAt,
                retrievedAt: board.retrievedAt,
              ),
            ),
          ),
        ),
        RatesSliver(rates: board.rates),
      ],
    );
  }
}

/// "Rates for 9 Sep 2026 · updated 3 hours ago"
class BoardCaption extends StatelessWidget {
  const BoardCaption({
    required this.publishedAt,
    required this.retrievedAt,
    super.key,
  });

  final DateTime? publishedAt;
  final DateTime retrievedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final published = publishedAt;
    final relative = retrievedAt.toRelativeLabel();

    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 15,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const Gap.horizontal(AppSpacing.xs),
        Expanded(
          child: Text(
            published == null
                ? AppStrings.updatedRelative(relative)
                : AppStrings.ratesForDateUpdated(
                    published.toMediumDate(),
                    relative,
                  ),
            maxLines: 2,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// The list itself: a single column on phones, a grid once there is room.
///
/// Wide screens get columns rather than a stretched list because a 1200dp-wide
/// row wastes the space *and* makes each row harder to read.
class RatesSliver extends StatelessWidget {
  const RatesSliver({required this.rates, super.key});

  final List<CurrencyRate> rates;

  @override
  Widget build(BuildContext context) {
    final columns = context.gridColumns;

    if (columns == 1) {
      return ResponsiveSliverCenter(
        sliver: SliverList.separated(
          itemCount: rates.length,
          separatorBuilder: (_, _) => const Gap(AppSpacing.md),
          itemBuilder: (context, index) => RateCardTile(rate: rates[index]),
        ),
      );
    }

    return ResponsiveSliverCenter(
      maxWidth: AppBreakpoints.maxWideContentWidth,
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          // Tall enough for the stacked card layout that appears when a cell
          // is narrower than ~340dp (typical in a 3-column grid).
          mainAxisExtent: 160,
        ),
        itemCount: rates.length,
        itemBuilder: (context, index) => RateCardTile(rate: rates[index]),
      ),
    );
  }
}

/// [RateCard] wired to the detail route.
class RateCardTile extends StatelessWidget {
  const RateCardTile({required this.rate, super.key});

  final CurrencyRate rate;

  @override
  Widget build(BuildContext context) {
    return RateCard(
      rate: rate,
      onTap: () => context.push(AppRoutes.currencyDetailPath(rate.currency)),
    );
  }
}

/// Full-screen shimmer for the first load. One skeleton per tracked currency,
/// so the placeholder count matches what will arrive.
class RatesSkeletonSliver extends StatelessWidget {
  const RatesSkeletonSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final columns = context.gridColumns;

    return ResponsiveSliverCenter(
      maxWidth: columns == 1
          ? AppBreakpoints.maxContentWidth
          : AppBreakpoints.maxWideContentWidth,
      sliver: SliverToBoxAdapter(
        child: ShimmerGroup(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: Column(
              children: [
                for (var index = 0; index < Currency.values.length; index++)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: RateCardSkeleton(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
