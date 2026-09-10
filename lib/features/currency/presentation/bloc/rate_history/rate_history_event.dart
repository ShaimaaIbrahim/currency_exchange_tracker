part of 'package:currency_exchange_tracker/features/currency/presentation/bloc/rate_history/rate_history_bloc.dart';

sealed class RateHistoryEvent extends Equatable {
  const RateHistoryEvent();

  @override
  List<Object?> get props => const [];
}

/// Load (or reload) the series for [currency].
final class RateHistoryRequested extends RateHistoryEvent {
  const RateHistoryRequested(this.currency);

  final Currency currency;

  @override
  List<Object?> get props => [currency];
}

/// Retry after a failure, reusing the currency already in state.
final class RateHistoryRetried extends RateHistoryEvent {
  const RateHistoryRetried();
}
