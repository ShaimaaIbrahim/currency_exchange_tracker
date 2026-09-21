import 'package:currency_exchange_tracker/core/constants/app_strings.dart';
import 'package:currency_exchange_tracker/core/responsive/responsive_context.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/core/widgets/app_state_views.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/rate_history/rate_history_bloc.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/rate_history_chart.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/rate_history_chart_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The chart, its shimmer, and its own error/empty handling.
///
/// Failures are contained here rather than replacing the page, so a chart
/// outage never hides the summary the user came for.
class RateHistorySection extends StatelessWidget {
  const RateHistorySection({required this.currency, super.key});

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
              AppStrings.last7Days,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(AppSpacing.xxs),
            Text(
              AppStrings.egpPerUnit(currency.code),
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
                builder: (context, state) => RateHistoryChartBody(state: state),
              ),
            ),
            const PartialHistoryNote(),
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

class RateHistoryChartBody extends StatelessWidget {
  const RateHistoryChartBody({required this.state, super.key});

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
        title: AppStrings.noHistoryTitle,
        message: AppStrings.noHistoryMessage,
        actionLabel: AppStrings.tryAgain,
        onAction: () =>
            context.read<RateHistoryBloc>().add(const RateHistoryRetried()),
      );
    }

    // One data point is a dot, not a trend — say so instead of drawing a
    // meaningless flat line.
    if (!history.isPlottable) {
      return AppMessageView(
        icon: Icons.timeline_rounded,
        title: AppStrings.notEnoughHistoryTitle,
        message: AppStrings.notEnoughHistoryMessage(history.currency.code),
        actionLabel: AppStrings.tryAgain,
        onAction: () =>
            context.read<RateHistoryBloc>().add(const RateHistoryRetried()),
      );
    }

    return RateHistoryChart(history: history);
  }
}

/// Honest footnote when the feed skipped days inside the window.
class PartialHistoryNote extends StatelessWidget {
  const PartialHistoryNote({super.key});

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
                  AppStrings.partialHistoryNote(
                    shown: history.points.length,
                    requested: history.requestedDays,
                  ),
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
