import 'package:currency_exchange_tracker/core/di/injector.dart';
import 'package:currency_exchange_tracker/core/router/app_router.dart';
import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/connectivity/connectivity_cubit.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/exchange_rates/exchange_rates_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Root widget: providers, theme and router.
class CurrencyExchangeApp extends StatefulWidget {
  const CurrencyExchangeApp({super.key});

  @override
  State<CurrencyExchangeApp> createState() => _CurrencyExchangeAppState();
}

class _CurrencyExchangeAppState extends State<CurrencyExchangeApp> {
  /// Built once and held in state. Rebuilding a `GoRouter` on every frame
  /// resets the navigation stack.
  late final GoRouter _router = AppRouter.create();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // App-scoped: the board is shared by the list and the detail summary,
        // so the detail screen can render instantly without a second fetch.
        BlocProvider<ExchangeRatesBloc>(
          create: (_) =>
              sl<ExchangeRatesBloc>()..add(const ExchangeRatesRequested()),
        ),
        BlocProvider<ConnectivityCubit>(
          create: (_) => sl<ConnectivityCubit>()..start(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Currency Exchange Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: _router,
        builder: (context, child) {
          // Respect the user's text-size preference, but cap it: past ~1.6×
          // the numeric layouts stop being readable no matter how they wrap,
          // and clamping is kinder than clipping.
          final scaler = MediaQuery.textScalerOf(context)
              .clamp(minScaleFactor: 0.85, maxScaleFactor: 1.6);
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scaler),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
