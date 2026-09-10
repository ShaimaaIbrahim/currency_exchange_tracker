part of 'package:currency_exchange_tracker/features/currency/presentation/bloc/rate_history/rate_history_bloc.dart';

enum RateHistoryStatus { initial, loading, success, failure }

class RateHistoryState extends Equatable {
  const RateHistoryState({
    this.status = RateHistoryStatus.initial,
    this.currency,
    this.history,
    this.failure,
  });

  final RateHistoryStatus status;

  /// Retained across retries so [RateHistoryRetried] needs no payload.
  final Currency? currency;

  final RateHistory? history;
  final Failure? failure;

  /// Shimmer is shown for both `initial` and `loading`: the gap between
  /// constructing the bloc and the first event is a frame the user can see.
  bool get isLoading =>
      status == RateHistoryStatus.initial ||
      status == RateHistoryStatus.loading;

  bool get hasFailure => status == RateHistoryStatus.failure;

  /// Loaded, but the window contained no usable points.
  bool get isEmpty =>
      status == RateHistoryStatus.success && (history?.isEmpty ?? true);

  /// Enough points to draw a line.
  bool get isPlottable => history?.isPlottable ?? false;

  RateHistoryState copyWith({
    RateHistoryStatus? status,
    Currency? currency,
    RateHistory? history,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return RateHistoryState(
      status: status ?? this.status,
      currency: currency ?? this.currency,
      history: history ?? this.history,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, currency, history, failure];
}
