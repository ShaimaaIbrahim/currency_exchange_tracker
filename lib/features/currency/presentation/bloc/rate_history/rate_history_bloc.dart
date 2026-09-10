import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:currency_exchange_tracker/core/error/failures.dart';
import 'package:currency_exchange_tracker/core/utils/result.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/currency/domain/usecases/get_rate_history.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'package:currency_exchange_tracker/features/currency/presentation/bloc/rate_history/rate_history_event.dart';
part 'package:currency_exchange_tracker/features/currency/presentation/bloc/rate_history/rate_history_state.dart';

/// Drives Module 2's chart.
///
/// Separate from [ExchangeRatesBloc] on purpose: it has a different lifetime
/// (one instance per detail screen, disposed on pop), a different failure
/// surface (an empty chart, not an empty app), and it must not be able to
/// invalidate the list behind it.
class RateHistoryBloc extends Bloc<RateHistoryEvent, RateHistoryState> {
  RateHistoryBloc({required GetRateHistory getRateHistory})
    : _getRateHistory = getRateHistory,
      super(const RateHistoryState()) {
    // `restartable`: if the user switches currency mid-fetch, the in-flight
    // request is abandoned so a slow earlier response cannot overwrite the
    // newer one.
    on<RateHistoryRequested>(_onRequested, transformer: restartable());
    on<RateHistoryRetried>(_onRetried, transformer: restartable());
  }

  final GetRateHistory _getRateHistory;

  Future<void> _onRequested(
    RateHistoryRequested event,
    Emitter<RateHistoryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RateHistoryStatus.loading,
        currency: event.currency,
        clearFailure: true,
      ),
    );
    await _load(event.currency, emit);
  }

  Future<void> _onRetried(
    RateHistoryRetried event,
    Emitter<RateHistoryState> emit,
  ) async {
    final currency = state.currency;
    if (currency == null) return;

    emit(state.copyWith(status: RateHistoryStatus.loading, clearFailure: true));
    await _load(currency, emit);
  }

  Future<void> _load(Currency currency, Emitter<RateHistoryState> emit) async {
    final result = await _getRateHistory(
      GetRateHistoryParams(currency: currency),
    );

    switch (result) {
      case Ok(:final value):
        emit(
          RateHistoryState(
            status: RateHistoryStatus.success,
            currency: currency,
            history: value,
          ),
        );
      case Err(:final failure):
        emit(
          RateHistoryState(
            status: RateHistoryStatus.failure,
            currency: currency,
            failure: failure,
          ),
        );
    }
  }
}
