import 'dart:async';

import 'package:currency_exchange_tracker/features/currency/domain/usecases/watch_connectivity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'package:currency_exchange_tracker/features/currency/presentation/bloc/connectivity/connectivity_state.dart';

/// Owns the single source of truth for "are we online".
///
/// A Cubit rather than a Bloc because there are no meaningful *intents* here,
/// only an external signal to relay — modelling that as events would add
/// ceremony without adding clarity. It is kept separate from
/// `ExchangeRatesBloc` so connectivity can be observed by any screen without
/// dragging rate-loading logic along with it.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit(this._watchConnectivity) : super(const ConnectivityState());

  final WatchConnectivity _watchConnectivity;
  StreamSubscription<bool>? _subscription;

  /// Reads the current status, then subscribes to changes.
  Future<void> start() async {
    _apply(await _watchConnectivity.current());
    _subscription?.cancel().ignore();
    _subscription = _watchConnectivity().listen(_apply);
  }

  void _apply(bool isConnected) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: isConnected
            ? ConnectivityStatus.online
            : ConnectivityStatus.offline,
        wasOffline: state.wasOffline || !isConnected,
      ),
    );
  }

  /// Called after a successful reconnect-triggered refresh so the next
  /// online event does not fire another one.
  void acknowledgeReconnect() {
    if (isClosed) return;
    emit(state.copyWith(wasOffline: false));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
