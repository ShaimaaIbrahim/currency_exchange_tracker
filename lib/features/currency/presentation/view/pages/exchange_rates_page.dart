import 'dart:async';

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

/// Module 1 — the exchange-rate board.
///
/// Everything is built inside one `CustomScrollView` so `RefreshIndicator`
/// keeps working in every state: a user whose first load failed can still pull
/// to retry, which is exactly when they most want to.
class ExchangeRatesPage extends StatelessWidget {
  const ExchangeRatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Module 3: refresh the moment the network returns, but only if we
        // actually lost it — otherwise every connectivity event would refetch.
        BlocListener<ConnectivityCubit, ConnectivityState>(
          listenWhen: (previous, current) =>
              previous.isOffline && current.status.isOnline,
          listener: (context, state) {
            context.read<ExchangeRatesBloc>().add(
              const ExchangeRatesConnectionRestored(),
            );
            context.read<ConnectivityCubit>().acknowledgeReconnect();
          },
        ),
        // A failed *refresh* is a snackbar, not a screen: the user still has
        // usable data in front of them.
        BlocListener<ExchangeRatesBloc, ExchangeRatesState>(
          listenWhen: (previous, current) =>
              previous.refreshFailure != current.refreshFailure &&
              current.refreshFailure != null,
          listener: (context, state) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.refreshFailure!.message),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () => context.read<ExchangeRatesBloc>().add(
                    const ExchangeRatesRefreshRequested(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
      child: const _ExchangeRatesScaffold(),
    );
  }
}

class _ExchangeRatesScaffold extends StatelessWidget {
  const _ExchangeRatesScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator.adaptive(
          onRefresh: () => _refresh(context),
          child: CustomScrollView(
            // `always` keeps pull-to-refresh available even when the content
            // is shorter than the viewport (error and empty states).
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const _RatesAppBar(),
              BlocBuilder<ExchangeRatesBloc, ExchangeRatesState>(
                builder: (context, state) => _RatesBody(state: state),
              ),
              const SliverToBoxAdapter(child: Gap(AppSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }

  /// Awaits the next settled state so the refresh spinner disappears when the
  /// work is actually done, not one frame after the gesture.
  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<ExchangeRatesBloc>()
      ..add(const ExchangeRatesRefreshRequested());
    try {
      await bloc.stream
          .firstWhere((state) => !state.isRefreshing && !state.isLoading)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      // The indicator dismisses; a later emission will still update the UI.
    }
  }
}

class _RatesAppBar extends StatelessWidget {
  const _RatesAppBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      // Two-line title (title + subtitle) needs more than the default 56dp.
      toolbarHeight: 72,
      titleSpacing: context.pagePadding,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Exchange Rates',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.appBarTheme.titleTextStyle,
          ),
          Text(
            'Against the Egyptian Pound',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        BlocBuilder<ConnectivityCubit, ConnectivityState>(
          buildWhen: (previous, current) => previous.status != current.status,
          builder: (context, state) => state.isOffline
              ? const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: OfflineChip(),
                )
              : const SizedBox.shrink(),
        ),
        BlocBuilder<ExchangeRatesBloc, ExchangeRatesState>(
          buildWhen: (previous, current) =>
              previous.isRefreshing != current.isRefreshing,
          builder: (context, state) {
            return IconButton(
              onPressed: state.isRefreshing
                  ? null
                  : () => context.read<ExchangeRatesBloc>().add(
                      const ExchangeRatesRefreshRequested(),
                    ),
              tooltip: 'Refresh rates',
              icon: state.isRefreshing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.refresh_rounded),
            );
          },
        ),
        SizedBox(width: context.pagePadding - AppSpacing.sm),
      ],
    );
  }
}

class _RatesBody extends StatelessWidget {
  const _RatesBody({required this.state});

  final ExchangeRatesState state;

  @override
  Widget build(BuildContext context) {
    if (state.isInitial || (state.isLoading && !state.hasRates)) {
      return const _RatesSkeletonSliver();
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
              child: _BoardCaption(
                publishedAt: board.publishedAt,
                retrievedAt: board.retrievedAt,
              ),
            ),
          ),
        ),
        _RatesSliver(rates: board.rates),
      ],
    );
  }
}

class _BoardCaption extends StatelessWidget {
  const _BoardCaption({required this.publishedAt, required this.retrievedAt});

  final DateTime? publishedAt;
  final DateTime retrievedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final published = publishedAt;

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
                ? 'Updated ${retrievedAt.toRelativeLabel()}'
                : 'Rates for ${published.toMediumDate()} · updated '
                      '${retrievedAt.toRelativeLabel()}',
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
class _RatesSliver extends StatelessWidget {
  const _RatesSliver({required this.rates});

  final List<CurrencyRate> rates;

  @override
  Widget build(BuildContext context) {
    final columns = context.gridColumns;

    if (columns == 1) {
      return ResponsiveSliverCenter(
        sliver: SliverList.separated(
          itemCount: rates.length,
          separatorBuilder: (_, _) => const Gap(AppSpacing.md),
          itemBuilder: (context, index) => _RateCardTile(rate: rates[index]),
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
        itemBuilder: (context, index) => _RateCardTile(rate: rates[index]),
      ),
    );
  }
}

class _RateCardTile extends StatelessWidget {
  const _RateCardTile({required this.rate});

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
class _RatesSkeletonSliver extends StatelessWidget {
  const _RatesSkeletonSliver();

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
