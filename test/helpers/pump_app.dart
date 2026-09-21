import 'package:bloc_test/bloc_test.dart';
import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/connectivity/connectivity_cubit.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/exchange_rates/exchange_rates_bloc.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/rate_history/rate_history_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MockExchangeRatesBloc
    extends MockBloc<ExchangeRatesEvent, ExchangeRatesState>
    implements ExchangeRatesBloc {}

class MockRateHistoryBloc extends MockBloc<RateHistoryEvent, RateHistoryState>
    implements RateHistoryBloc {}

class MockConnectivityCubit extends MockCubit<ConnectivityState>
    implements ConnectivityCubit {}

extension PumpApp on WidgetTester {
  /// Mounts [widget] inside the real theme with whichever blocs the test
  /// supplies.
  ///
  /// Using the production theme means widget tests catch contrast and
  /// `ThemeExtension` regressions too, not just layout ones.
  Future<void> pumpApp(
    Widget widget, {
    ExchangeRatesBloc? exchangeRatesBloc,
    RateHistoryBloc? rateHistoryBloc,
    ConnectivityCubit? connectivityCubit,
    Size surfaceSize = const Size(390, 844),
    double textScale = 1.0,
  }) async {
    await binding.setSurfaceSize(surfaceSize);
    addTearDown(() => binding.setSurfaceSize(null));

    final providers = <BlocProvider<dynamic>>[
      if (exchangeRatesBloc != null)
        BlocProvider<ExchangeRatesBloc>.value(value: exchangeRatesBloc),
      if (rateHistoryBloc != null)
        BlocProvider<RateHistoryBloc>.value(value: rateHistoryBloc),
      if (connectivityCubit != null)
        BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
    ];

    await pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: surfaceSize,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: providers.isEmpty
              ? widget
              : MultiBlocProvider(providers: providers, child: widget),
        ),
      ),
    );
  }
}
