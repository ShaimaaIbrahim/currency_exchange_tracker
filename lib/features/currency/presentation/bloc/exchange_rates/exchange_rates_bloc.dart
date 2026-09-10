import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:currency_exchange_tracker/core/error/failures.dart';
import 'package:currency_exchange_tracker/core/utils/result.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rates_board.dart';
import 'package:currency_exchange_tracker/features/currency/domain/usecases/get_rates_board.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'package:currency_exchange_tracker/features/currency/presentation/bloc/exchange_rates/exchange_rates_event.dart';
part 'package:currency_exchange_tracker/features/currency/presentation/bloc/exchange_rates/exchange_rates_state.dart';

/// Drives Module 1: the exchange-rate board.
///
/// Knows only [GetRatesBoard]. It has no idea whether a board came from the
/// network or the cache — it forwards [RatesBoard.source] to the UI and lets
/// the widget decide how to label it. That is what keeps this class testable
/// without any HTTP or storage fakes.
class ExchangeRatesBloc extends Bloc<ExchangeRatesEvent, ExchangeRatesState> {
  ExchangeRatesBloc({required GetRatesBoard getRatesBoard})
    : _getRatesBoard = getRatesBoard,
      super(const ExchangeRatesState()) {
    // `droppable`: while a fetch is in flight, further requests are ignored.
    // Rate data is a single shared resource, so a second concurrent fetch can
    // only produce duplicate work and out-of-order emissions.
    on<ExchangeRatesRequested>(_onRequested, transformer: droppable());
    on<ExchangeRatesRefreshRequested>(
      _onRefreshRequested,
      transformer: droppable(),
    );
    on<ExchangeRatesConnectionRestored>(
      _onConnectionRestored,
      transformer: droppable(),
    );
  }

  final GetRatesBoard _getRatesBoard;

  Future<void> _onRequested(
    ExchangeRatesRequested event,
    Emitter<ExchangeRatesState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ExchangeRatesStatus.loading,
        clearFailure: true,
        clearRefreshFailure: true,
      ),
    );
    await _load(emit, forceRefresh: false, isBlocking: true);
  }

  Future<void> _onRefreshRequested(
    ExchangeRatesRefreshRequested event,
    Emitter<ExchangeRatesState> emit,
  ) async {
    // No data yet means pull-to-refresh is really a first load: show the
    // blocking state so the user does not stare at an empty screen.
    final isBlocking = !state.hasRates;
    emit(
      state.copyWith(
        status: isBlocking
            ? ExchangeRatesStatus.loading
            : ExchangeRatesStatus.refreshing,
        clearRefreshFailure: true,
      ),
    );
    await _load(emit, forceRefresh: true, isBlocking: isBlocking);
  }

  Future<void> _onConnectionRestored(
    ExchangeRatesConnectionRestored event,
    Emitter<ExchangeRatesState> emit,
  ) async {
    final isBlocking = !state.hasRates;
    emit(
      state.copyWith(
        status: isBlocking
            ? ExchangeRatesStatus.loading
            : ExchangeRatesStatus.refreshing,
        clearRefreshFailure: true,
      ),
    );
    await _load(emit, forceRefresh: true, isBlocking: isBlocking);
  }

  /// Shared tail for all three events.
  ///
  /// [isBlocking] decides where a failure lands: on a full-screen error view
  /// when there is nothing else to show, or on a dismissible snackbar when the
  /// user still has a usable (if stale) board in front of them.
  Future<void> _load(
    Emitter<ExchangeRatesState> emit, {
    required bool forceRefresh,
    required bool isBlocking,
  }) async {
    final result = await _getRatesBoard(
      GetRatesBoardParams(forceRefresh: forceRefresh),
    );

    switch (result) {
      case Ok(:final value):
        emit(
          ExchangeRatesState(status: ExchangeRatesStatus.success, board: value),
        );
      case Err(:final failure):
        if (isBlocking) {
          emit(
            ExchangeRatesState(
              status: ExchangeRatesStatus.failure,
              failure: failure,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: ExchangeRatesStatus.success,
              refreshFailure: failure,
            ),
          );
        }
    }
  }
}
