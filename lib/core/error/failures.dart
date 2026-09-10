import 'package:equatable/equatable.dart';

/// Domain-level description of "something went wrong".
///
/// Failures are the only error vocabulary the presentation layer knows about.
/// Every failure carries a [message] that is safe to show to a user, plus
/// [isRetryable] so the UI can decide whether to offer a *Try again* action
/// without pattern-matching on concrete types.
sealed class Failure extends Equatable {
  const Failure({required this.message, this.isRetryable = true});

  /// User-facing, already-humanised copy.
  final String message;

  /// Whether retrying the same operation could plausibly succeed.
  final bool isRetryable;

  @override
  List<Object?> get props => [message, isRetryable];
}

/// Device is offline and no cached data could stand in.
final class OfflineFailure extends Failure {
  const OfflineFailure()
    : super(
        message:
            'You appear to be offline and no saved rates are available yet. '
            'Connect to the internet and try again.',
      );
}

/// The request timed out.
final class TimeoutFailure extends Failure {
  const TimeoutFailure()
    : super(message: 'The connection is taking too long. Please try again.');
}

/// Host could not be reached at all.
final class ConnectionFailure extends Failure {
  const ConnectionFailure()
    : super(
        message:
            'We could not reach the exchange-rate service. '
            'Check your connection and try again.',
      );
}

/// Upstream service is broken (5xx).
final class ServerFailure extends Failure {
  const ServerFailure({this.statusCode})
    : super(
        message:
            'The exchange-rate service is temporarily unavailable. '
            'Please try again in a moment.',
      );

  final int? statusCode;

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Request itself was invalid — retrying verbatim will not help.
final class RequestFailure extends Failure {
  const RequestFailure({this.statusCode})
    : super(
        message: 'We could not load the exchange rates for this request.',
        isRetryable: false,
      );

  final int? statusCode;

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Response shape did not match expectations — a client/server contract bug.
final class ParsingFailure extends Failure {
  const ParsingFailure()
    : super(
        message:
            'We received an unexpected response and could not read the '
            'exchange rates.',
        isRetryable: false,
      );
}

/// The upstream feed simply has no data for the requested window.
final class NoDataFailure extends Failure {
  const NoDataFailure({String? message})
    : super(
        message:
            message ??
            'No exchange-rate data has been published for this period yet.',
        isRetryable: false,
      );
}

/// Local cache read/write blew up.
final class CacheFailure extends Failure {
  const CacheFailure()
    : super(message: 'We could not read the rates saved on this device.');
}

/// Catch-all for genuinely unexpected errors.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({this.cause})
    : super(message: 'Something went wrong. Please try again.');

  /// The original error. Kept for logging only — never rendered, because an
  /// exception's `toString()` is not user-facing copy.
  final Object? cause;

  @override
  List<Object?> get props => [...super.props, cause];
}
