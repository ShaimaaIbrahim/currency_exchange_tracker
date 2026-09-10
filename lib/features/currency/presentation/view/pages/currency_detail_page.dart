import 'package:currency_exchange_tracker/core/responsive/app_breakpoints.dart';
import 'package:currency_exchange_tracker/core/responsive/responsive_context.dart';
import 'package:currency_exchange_tracker/core/responsive/responsive_scroll_view.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/core/widgets/app_state_views.dart';
import 'package:currency_exchange_tracker/core/widgets/shimmer_box.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/exchange_rates/exchange_rates_bloc.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/rate_history/rate_history_bloc.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/rate_history_chart.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/rate_history_chart_shimmer.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/rate_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Module 2 — current rate, daily change, last-update date and the 7-day
/// chart.
///
/// The summary reads the rate straight out of [ExchangeRatesBloc] rather than
/// re-fetching it: the board is already in memory and re-requesting would
/// spend a round trip to render a number the user just tapped on.
class CurrencyDetailPage extends StatelessWidget {
  const CurrencyDetailPage({required this.currency, super.key});

  final Currency currency;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currency.pairLabel),
        actions: [
          BlocBuilder<RateHistoryBloc, RateHistoryState>(
            buildWhen: (previous, current) =>
                previous.isLoading != current.isLoading,
            builder: (context, state) => IconButton(
              tooltip: 'Reload chart',
              onPressed: state.isLoading
                  ? null
                  : () => context.read<RateHistoryBloc>().add(
                      const RateHistoryRetried(),
                    ),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          SizedBox(width: context.pagePadding - AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: ResponsiveCenter(
            maxWidth: AppBreakpoints.maxWideContentWidth,
            child: _DetailContent(currency: currency),
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.currency});

  final Currency currency;

  @override
  Widget build(BuildContext context) {
    // Side-by-side on wide screens: the summary is a tall narrow block and the
    // chart is a wide short one, so stacking them wastes a lot of screen.
    final isSideBySide = context.isAtLeastExpanded;

    final summary = _SummarySection(currency: currency);
    final chart = _ChartSection(currency: currency);

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

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.currency});

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
          return _SummaryFallback(state: state, currency: currency);
        }
        return RateSummaryCard(rate: rate);
      },
    );
  }
}

class _SummaryFallback extends StatelessWidget {
  const _SummaryFallback({required this.state, required this.currency});

  final ExchangeRatesState state;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading || state.isInitial) {
      return const _SummarySkeleton();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: AppMessageView(
          icon: Icons.info_outline_rounded,
          title: 'Rate unavailable',
          message:
              'We do not have a current ${currency.code} rate yet. '
              'The chart below still works.',
          actionLabel: 'Load rates',
          onAction: () => context.read<ExchangeRatesBloc>().add(
            const ExchangeRatesRefreshRequested(),
          ),
        ),
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

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

/// The chart, its shimmer, and its own error/empty handling.
///
/// Failures are contained here rather than replacing the page, so a chart
/// outage never hides the summary the user came for.
class _ChartSection extends StatelessWidget {
  const _ChartSection({required this.currency});

  final Currency currency;

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
            Text(
              'Last 7 days',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(AppSpacing.xxs),
            Text(
              'EGP per 1 ${currency.code}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(AppSpacing.lg),
            SizedBox(
              // A chart shorter than ~200dp cannot show a trend; taller than
              // 40% of the viewport pushes the summary off-screen.
              height: _chartHeight(context),
              child: BlocBuilder<RateHistoryBloc, RateHistoryState>(
                builder: (context, state) => _ChartBody(state: state),
              ),
            ),
            const _PartialDataNote(),
          ],
        ),
      ),
    );
  }

  static double _chartHeight(BuildContext context) {
    final byViewport = context.screenHeight * 0.34;
    final ceiling = context.responsive<double>(compact: 280, medium: 340);
    return byViewport.clamp(200.0, ceiling);
  }
}

class _ChartBody extends StatelessWidget {
  const _ChartBody({required this.state});

  final RateHistoryState state;

  @override
  Widget build(BuildContext context) {
    // Shimmer, per the spec — never a spinner.
    if (state.isLoading) return const RateHistoryChartShimmer();

    if (state.hasFailure && state.failure != null) {
      return AppMessageView.fromFailure(
        state.failure!,
        onRetry: () =>
            context.read<RateHistoryBloc>().add(const RateHistoryRetried()),
      );
    }

    final history = state.history;

    if (history == null || history.isEmpty) {
      return AppMessageView(
        icon: Icons.show_chart_rounded,
        title: 'No history yet',
        message:
            'The feed has not published rates for this currency over the '
            'last 7 days.',
        actionLabel: 'Try again',
        onAction: () =>
            context.read<RateHistoryBloc>().add(const RateHistoryRetried()),
      );
    }

    // One data point is a dot, not a trend — say so instead of drawing a
    // meaningless flat line.
    if (!history.isPlottable) {
      return AppMessageView(
        icon: Icons.timeline_rounded,
        title: 'Not enough history',
        message:
            'Only one day of ${history.currency.code} data is available, '
            'which is not enough to draw a trend.',
        actionLabel: 'Try again',
        onAction: () =>
            context.read<RateHistoryBloc>().add(const RateHistoryRetried()),
      );
    }

    return RateHistoryChart(history: history);
  }
}

/// Honest footnote when the feed skipped days inside the window.
class _PartialDataNote extends StatelessWidget {
  const _PartialDataNote();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RateHistoryBloc, RateHistoryState>(
      buildWhen: (previous, current) => previous.history != current.history,
      builder: (context, state) {
        final history = state.history;
        if (history == null || !history.isPartial || !history.isPlottable) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const Gap.horizontal(AppSpacing.xs),
              Expanded(
                child: Text(
                  'Showing ${history.points.length} of the last '
                  '${history.requestedDays} days — the feed did not publish '
                  'rates on the missing dates.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
