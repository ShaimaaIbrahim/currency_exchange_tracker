import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity status, abstracted so the repository does not depend on
/// `connectivity_plus` and tests can flip the network with a stream controller.
abstract interface class NetworkInfo {
  /// Whether the device currently reports a usable network interface.
  Future<bool> get isConnected;

  /// Emits on every transition. Duplicate values are filtered out, so a
  /// listener only wakes up when the answer actually changed.
  Stream<bool> get onStatusChange;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  @override
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_hasConnection).distinct();

  /// `connectivity_plus` reports the *interfaces* that are up, not real
  /// reachability. Treating `none` (and the empty list some platforms emit) as
  /// offline and everything else as online is the right trade-off here: a
  /// false "online" still surfaces as a [ConnectionFailure] from the request
  /// itself, whereas a false "offline" would needlessly block a working fetch.
  static bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((result) => result != ConnectivityResult.none);
  }
}
