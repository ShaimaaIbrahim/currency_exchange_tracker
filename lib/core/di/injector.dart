import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:currency_exchange_tracker/core/network/api_client.dart';
import 'package:currency_exchange_tracker/core/network/network_info.dart';
import 'package:currency_exchange_tracker/features/currency/data/datasources/currency_local_data_source.dart';
import 'package:currency_exchange_tracker/features/currency/data/datasources/currency_remote_data_source.dart';
import 'package:currency_exchange_tracker/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:currency_exchange_tracker/features/currency/domain/repositories/currency_repository.dart';
import 'package:currency_exchange_tracker/features/currency/domain/usecases/get_rate_history.dart';
import 'package:currency_exchange_tracker/features/currency/domain/usecases/get_rates_board.dart';
import 'package:currency_exchange_tracker/features/currency/domain/usecases/watch_connectivity.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/connectivity/connectivity_cubit.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/exchange_rates/exchange_rates_bloc.dart';
import 'package:currency_exchange_tracker/features/currency/presentation/bloc/rate_history/rate_history_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt sl = GetIt.instance;

/// Wires the object graph, outermost layer first.
///
/// Registration is hand-written rather than generated: the graph is small
/// enough that codegen would cost more (build_runner in CI, generated files in
/// review) than the twenty lines it saves, and an explicit graph is something
/// a reader can follow top to bottom.
Future<void> configureDependencies() async {
  // ── External ──────────────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<Connectivity>(Connectivity.new)
    ..registerLazySingleton<ApiClient>(ApiClient.new)
    // ── Core ────────────────────────────────────────────────────────────────
    ..registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()))
    // ── Data sources ────────────────────────────────────────────────────────
    ..registerLazySingleton<CurrencyRemoteDataSource>(
      () => CurrencyRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<CurrencyLocalDataSource>(
      () => CurrencyLocalDataSourceImpl(sl()),
    )
    // ── Repository ──────────────────────────────────────────────────────────
    ..registerLazySingleton<CurrencyRepository>(
      () =>
          CurrencyRepositoryImpl(remote: sl(), local: sl(), networkInfo: sl()),
    )
    // ── Use cases ───────────────────────────────────────────────────────────
    ..registerLazySingleton<GetRatesBoard>(() => GetRatesBoard(sl()))
    ..registerLazySingleton<GetRateHistory>(() => GetRateHistory(sl()))
    ..registerLazySingleton<WatchConnectivity>(() => WatchConnectivity(sl()))
    // ── BLoCs ───────────────────────────────────────────────────────────────
    // `registerFactory`, not singleton: each screen gets a fresh bloc whose
    // lifetime is the screen's, so a popped detail page cannot keep emitting.
    ..registerFactory<ExchangeRatesBloc>(
      () => ExchangeRatesBloc(getRatesBoard: sl()),
    )
    ..registerFactory<RateHistoryBloc>(
      () => RateHistoryBloc(getRateHistory: sl()),
    )
    // The one exception: connectivity is app-wide and must survive navigation.
    ..registerLazySingleton<ConnectivityCubit>(() => ConnectivityCubit(sl()));
}

/// Test hook — drops every registration so each test starts from a clean graph.
Future<void> resetDependencies() => sl.reset();
