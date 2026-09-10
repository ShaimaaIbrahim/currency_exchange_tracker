import 'dart:io';

import 'package:currency_exchange_tracker/core/error/exceptions.dart';
import 'package:dio/dio.dart';

/// Translates transport-level errors into the app's [AppException] vocabulary.
///
/// This is deliberately the *only* place in the codebase that knows Dio
/// exists, which is what makes swapping the HTTP client a one-file change.
abstract final class DioExceptionMapper {
  /// [requestedDate] lets a 404 be reported as
  /// [RatesNotPublishedException] — the difference between "the feed has no
  /// data for that day" and "something is broken" matters to the caller.
  static AppException map(DioException error, {DateTime? requestedDate}) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return RequestTimeoutException(cause: error);

      case DioExceptionType.cancel:
        return RequestCancelledException(cause: error);

      case DioExceptionType.connectionError:
        return ConnectionException(cause: error);

      case DioExceptionType.badCertificate:
        return ConnectionException(cause: error);

      case DioExceptionType.badResponse:
        return _mapStatus(
          error.response?.statusCode,
          error,
          requestedDate: requestedDate,
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return ConnectionException(cause: error);
        }
        if (error.error is FormatException) {
          return ParsingException(cause: error);
        }
        return ConnectionException(cause: error);
    }
  }

  static AppException _mapStatus(
    int? statusCode,
    DioException error, {
    DateTime? requestedDate,
  }) {
    if (statusCode == null) {
      return ServerException(cause: error);
    }
    if (statusCode == HttpStatus.notFound && requestedDate != null) {
      return RatesNotPublishedException(requestedDate, cause: error);
    }
    if (statusCode >= 500) {
      return ServerException(statusCode: statusCode, cause: error);
    }
    if (statusCode >= 400) {
      return ClientRequestException(statusCode: statusCode, cause: error);
    }
    return ServerException(statusCode: statusCode, cause: error);
  }
}
