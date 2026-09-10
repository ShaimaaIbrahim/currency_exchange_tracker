import 'package:currency_exchange_tracker/core/error/exceptions.dart';
import 'package:currency_exchange_tracker/core/error/failures.dart';

/// Single translation table from data-layer [AppException]s to domain
/// [Failure]s.
///
/// Centralising it means error copy is written once, and the exhaustive
/// `switch` over the sealed exception hierarchy makes the compiler flag any
/// new exception type that nobody has decided how to present yet.
abstract final class FailureMapper {
  static Failure fromException(Object error) {
    if (error is! AppException) return UnexpectedFailure(cause: error);

    return switch (error) {
      NoConnectionException() => const OfflineFailure(),
      RequestTimeoutException() => const TimeoutFailure(),
      ConnectionException() => const ConnectionFailure(),
      ServerException(:final statusCode) => ServerFailure(
        statusCode: statusCode,
      ),
      ClientRequestException(:final statusCode) => RequestFailure(
        statusCode: statusCode,
      ),
      RatesNotPublishedException() => const NoDataFailure(),
      ParsingException() => const ParsingFailure(),
      CacheException() => const CacheFailure(),
      CacheMissException() => const OfflineFailure(),
      // Cancellation is a normal consequence of navigating away. It should
      // never be rendered, but a failure is still needed to close the future.
      RequestCancelledException() => const NoDataFailure(
        message: 'The request was cancelled.',
      ),
    };
  }
}
