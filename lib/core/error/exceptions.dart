/// Low-level exceptions thrown by the **data** layer.
///
/// Data sources never leak `DioException`, `FormatException` or platform
/// errors upwards. They translate them into one of the types below, and the
/// repository is the single place that maps them onto `Failure`s.
library;

/// Base type for every exception raised inside the data layer.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// The device reported no usable connection before the request was attempted.
final class NoConnectionException extends AppException {
  const NoConnectionException({super.cause})
    : super('No internet connection available.');
}

/// The request was issued but did not complete in time.
final class RequestTimeoutException extends AppException {
  const RequestTimeoutException({super.cause})
    : super('The request took too long to complete.');
}

/// DNS/socket level problem — host unreachable, TLS handshake failure, etc.
final class ConnectionException extends AppException {
  const ConnectionException({super.cause})
    : super('Could not reach the exchange-rate service.');
}

/// Server answered with a 5xx status code.
final class ServerException extends AppException {
  const ServerException({this.statusCode, super.cause})
    : super('The exchange-rate service is currently unavailable.');

  final int? statusCode;
}

/// Server answered with a 4xx status code other than 404.
final class ClientRequestException extends AppException {
  const ClientRequestException({this.statusCode, super.cause})
    : super('The exchange-rate request was rejected.');

  final int? statusCode;
}

/// No rates were published for the requested date (typically a 404).
///
/// This is an expected outcome rather than a defect: the upstream feed only
/// publishes on days it has data for, so callers routinely skip these dates.
final class RatesNotPublishedException extends AppException {
  const RatesNotPublishedException(this.date, {super.cause})
    : super('No rates were published for the requested date.');

  final DateTime date;
}

/// The payload was received but could not be understood.
final class ParsingException extends AppException {
  const ParsingException({super.cause})
    : super('Received an unexpected response format.');
}

/// Reading or writing the local cache failed.
final class CacheException extends AppException {
  const CacheException({super.cause}) : super('Could not access local cache.');
}

/// Nothing usable is stored locally.
final class CacheMissException extends AppException {
  const CacheMissException() : super('No cached rates are available yet.');
}

/// The request was cancelled (e.g. the user left the screen mid-flight).
final class RequestCancelledException extends AppException {
  const RequestCancelledException({super.cause})
    : super('The request was cancelled.');
}
