import 'dart:async';

import 'package:currency_exchange_tracker/core/constants/app_strings.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/connectivity/connectivity_cubit.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/exchange_rates/exchange_rates_bloc.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/rates_app_bar.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/rates_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
                  label: AppStrings.retry,
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
              const RatesAppBar(),
              BlocBuilder<ExchangeRatesBloc, ExchangeRatesState>(
                builder: (context, state) => RatesBody(state: state),
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
