import 'package:currency_exchange_tracker/features/currency/domain/repositories/currency_repository.dart';

/// Observes connectivity so the app can auto-refresh the moment the network
/// comes back (Module 3).
///
/// Returns a plain `Stream<bool>` rather than a `Result`, because a
/// connectivity stream has no failure mode worth surfacing to the user.
class WatchConnectivity {
  const WatchConnectivity(this._repository);

  final CurrencyRepository _repository;

  Stream<bool> call() => _repository.watchConnectivity();

  /// One-shot read, used to render the correct state on first frame instead of
  /// waiting for the first stream event.
  Future<bool> current() => _repository.isConnected();
}
