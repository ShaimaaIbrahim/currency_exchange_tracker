import 'package:currency_exchange_tracker/core/constants/app_strings.dart';
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
  const OfflineFailure() : super(message: AppStrings.failureOfflineMessage);
}

/// The request timed out.
final class TimeoutFailure extends Failure {
  const TimeoutFailure() : super(message: AppStrings.failureTimeoutMessage);
}

/// Host could not be reached at all.
final class ConnectionFailure extends Failure {
  const ConnectionFailure()
    : super(message: AppStrings.failureConnectionMessage);
}

/// Upstream service is broken (5xx).
final class ServerFailure extends Failure {
  const ServerFailure({this.statusCode})
    : super(message: AppStrings.failureServerMessage);

  final int? statusCode;

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Request itself was invalid — retrying verbatim will not help.
final class RequestFailure extends Failure {
  const RequestFailure({this.statusCode})
    : super(message: AppStrings.failureRequestMessage, isRetryable: false);

  final int? statusCode;

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Response shape did not match expectations — a client/server contract bug.
final class ParsingFailure extends Failure {
  const ParsingFailure()
    : super(message: AppStrings.failureParsingMessage, isRetryable: false);
}

/// The upstream feed simply has no data for the requested window.
final class NoDataFailure extends Failure {
  const NoDataFailure({String? message})
    : super(
        message: message ?? AppStrings.failureNoDataMessage,
        isRetryable: false,
      );
}

/// Local cache read/write blew up.
final class CacheFailure extends Failure {
  const CacheFailure() : super(message: AppStrings.failureCacheMessage);
}

/// Catch-all for genuinely unexpected errors.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({this.cause})
    : super(message: AppStrings.failureUnexpectedMessage);

  /// The original error. Kept for logging only — never rendered, because an
  /// exception's `toString()` is not user-facing copy.
  final Object? cause;

  @override
  List<Object?> get props => [...super.props, cause];
}
