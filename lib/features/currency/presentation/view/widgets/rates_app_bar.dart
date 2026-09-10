import 'package:currency_exchange_tracker/core/constants/app_strings.dart';
import 'package:currency_exchange_tracker/core/responsive/responsive_context.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/connectivity/connectivity_cubit.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/exchange_rates/exchange_rates_bloc.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/offline_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pinned two-line app bar for the exchange-rate board.
class RatesAppBar extends StatelessWidget {
  const RatesAppBar({super.key});

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
            AppStrings.ratesTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.appBarTheme.titleTextStyle,
          ),
          Text(
            AppStrings.ratesSubtitle,
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
              tooltip: AppStrings.refreshRatesTooltip,
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
