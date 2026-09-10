part of 'package:currency_exchange_tracker/features/currency/presentation/bloc/exchange_rates/exchange_rates_bloc.dart';

sealed class ExchangeRatesEvent extends Equatable {
  const ExchangeRatesEvent();

  @override
  List<Object?> get props => const [];
}

/// First load for the screen. Shows the full-screen shimmer.
final class ExchangeRatesRequested extends ExchangeRatesEvent {
  const ExchangeRatesRequested();
}

/// Pull-to-refresh. Keeps the existing list on screen while re-fetching, so
/// the content does not collapse under the user's finger.
final class ExchangeRatesRefreshRequested extends ExchangeRatesEvent {
  const ExchangeRatesRefreshRequested();
}

/// Connectivity came back — refresh silently, with no spinner, because the
/// user did not ask for anything.
final class ExchangeRatesConnectionRestored extends ExchangeRatesEvent {
  const ExchangeRatesConnectionRestored();
}
