import 'package:currency_exchange_tracker/core/constants/app_strings.dart';
import 'package:currency_exchange_tracker/core/di/injector.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/rate_history/rate_history_bloc.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/pages/currency_detail_page.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/pages/exchange_rates_page.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/view/pages/route_not_found_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const String rates = '/';
  static const String currencyDetail = '/currency/:code';

  /// Type-safe path builder, so no call site has to hand-assemble the URL.
  static String currencyDetailPath(Currency currency) =>
      '/currency/${currency.code.toLowerCase()}';
}

/// Declarative routing.
///
/// The currency code travels in the **path**, not in `extra`, so a detail
/// screen survives a deep link, a hot restart and a web refresh. That is also
/// why the code is re-resolved from the path parameter here rather than the
/// entity being passed by reference.
abstract final class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: AppRoutes.rates,
      routes: [
        GoRoute(
          path: AppRoutes.rates,
          name: 'rates',
          builder: (context, state) => const ExchangeRatesPage(),
          routes: [
            GoRoute(
              path: 'currency/:code',
              name: 'currencyDetail',
              builder: (context, state) {
                final code = state.pathParameters['code'] ?? '';
                final currency = Currency.fromCode(code);

                if (currency == null) {
                  return RouteNotFoundPage(
                    message: AppStrings.untrackedCurrency(code),
                  );
                }

                // The bloc is provided here rather than inside the page so the
                // page stays a pure widget that any test can pump with a fake.
                return BlocProvider<RateHistoryBloc>(
                  create: (_) =>
                      sl<RateHistoryBloc>()
                        ..add(RateHistoryRequested(currency)),
                  child: CurrencyDetailPage(currency: currency),
                );
              },
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) =>
          RouteNotFoundPage(message: AppStrings.unknownRoute('${state.uri}')),
    );
  }
}
