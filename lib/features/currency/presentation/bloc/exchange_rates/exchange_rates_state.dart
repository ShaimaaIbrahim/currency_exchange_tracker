part of 'package:currency_exchange_tracker/features/currency/presentation/bloc/exchange_rates/exchange_rates_bloc.dart';

enum ExchangeRatesStatus {
  initial,

  /// First load — nothing to show yet, so the screen renders shimmer.
  loading,

  /// Re-fetching while data is already on screen.
  refreshing,

  success,

  /// Load failed *and* there is nothing cached to show instead.
  failure,
}

/// A single state class with a [status] field, rather than one class per
/// state.
///
/// The screen needs to render "refreshing **with** the old list still visible"
/// and "loaded **but** the last refresh failed". Separate state classes would
/// each have to carry the previous board anyway, so the flag-plus-payload
/// shape ends up both smaller and harder to get wrong.
class ExchangeRatesState extends Equatable {
  const ExchangeRatesState({
    this.status = ExchangeRatesStatus.initial,
    this.board,
    this.failure,
    this.refreshFailure,
  });

  final ExchangeRatesStatus status;

  /// Last successfully loaded board, from network or cache.
  final RatesBoard? board;

  /// Blocking failure: there is nothing to render.
  final Failure? failure;

  /// Non-blocking failure: a refresh failed but [board] is still valid. Shown
  /// as a snackbar, not as a full-screen error.
  final Failure? refreshFailure;

  bool get isInitial => status == ExchangeRatesStatus.initial;

  bool get isLoading => status == ExchangeRatesStatus.loading;

  bool get isRefreshing => status == ExchangeRatesStatus.refreshing;

  bool get hasFailure => status == ExchangeRatesStatus.failure;

  bool get hasRates => (board?.rates.isNotEmpty ?? false);

  /// Loaded successfully but the feed returned no tracked currencies — the
  /// empty state, which is distinct from both loading and error.
  bool get isEmpty =>
      status == ExchangeRatesStatus.success && (board?.isEmpty ?? true);

  /// Whether to surface the "showing saved data" banner.
  bool get isShowingCachedData => board?.isFromCache ?? false;

  ExchangeRatesState copyWith({
    ExchangeRatesStatus? status,
    RatesBoard? board,
    Failure? failure,
    Failure? refreshFailure,
    bool clearFailure = false,
    bool clearRefreshFailure = false,
  }) {
    return ExchangeRatesState(
      status: status ?? this.status,
      board: board ?? this.board,
      failure: clearFailure ? null : (failure ?? this.failure),
      refreshFailure: clearRefreshFailure
          ? null
          : (refreshFailure ?? this.refreshFailure),
    );
  }

  @override
  List<Object?> get props => [status, board, failure, refreshFailure];
}
