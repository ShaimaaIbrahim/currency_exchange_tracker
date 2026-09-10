import 'package:currency_exchange_tracker/core/constants/app_strings.dart';
import 'package:currency_exchange_tracker/core/responsive/app_breakpoints.dart';
import 'package:currency_exchange_tracker/core/responsive/responsive_context.dart';
import 'package:currency_exchange_tracker/core/responsive/responsive_scroll_view.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/rate_history/rate_history_bloc.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/widgets/currency_detail_content.dart';
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
              tooltip: AppStrings.reloadChartTooltip,
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
            child: CurrencyDetailContent(currency: currency),
          ),
        ),
      ),
    );
  }
}
