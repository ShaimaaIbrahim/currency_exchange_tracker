part of 'package:currency_exchange_tracker/features/currency/presentation/bloc/connectivity/connectivity_cubit.dart';

enum ConnectivityStatus {
  /// Before the first reading arrives. The UI shows no banner yet, to avoid a
  /// false "offline" flash on cold start.
  unknown,
  online,
  offline;

  bool get isOffline => this == ConnectivityStatus.offline;

  bool get isOnline => this == ConnectivityStatus.online;
}

class ConnectivityState extends Equatable {
  const ConnectivityState({
    this.status = ConnectivityStatus.unknown,
    this.wasOffline = false,
  });

  final ConnectivityStatus status;

  /// True once the device has been offline at least once in this session.
  ///
  /// Needed to distinguish "came back online" (which must trigger a refresh)
  /// from "was online all along" (which must not re-fetch on every event).
  final bool wasOffline;

  bool get isOffline => status.isOffline;

  ConnectivityState copyWith({ConnectivityStatus? status, bool? wasOffline}) {
    return ConnectivityState(
      status: status ?? this.status,
      wasOffline: wasOffline ?? this.wasOffline,
    );
  }

  @override
  List<Object?> get props => [status, wasOffline];
}
