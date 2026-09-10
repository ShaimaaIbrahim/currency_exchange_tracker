import 'package:currency_exchange_tracker/core/constants/app_constants.dart';
import 'package:currency_exchange_tracker/core/error/exceptions.dart';
import 'package:currency_exchange_tracker/core/network/dio_exception_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Thin HTTP facade over Dio.
///
/// Responsibilities stop at "make the call, hand back a decoded map, or throw
/// an [AppException]". No domain knowledge, no caching, no retries policy
/// beyond the transport-level one configured below.
class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.requestTimeout,
        sendTimeout: AppConstants.requestTimeout,
        responseType: ResponseType.json,
        headers: const {'Accept': 'application/json'},
        // Non-2xx is handled by DioExceptionMapper, not by silently returning
        // an error body to the caller.
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          responseHeader: false,
          responseBody: false,
        ),
      );
    }

    return dio;
  }

  /// GETs [url] and returns the decoded JSON object.
  ///
  /// Throws:
  /// * [RatesNotPublishedException] when [requestedDate] is given and the feed
  ///   answers 404,
  /// * any other [AppException] for transport, server or parsing problems.
  Future<Map<String, dynamic>> getJson(
    String url, {
    DateTime? requestedDate,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Object?>(url, cancelToken: cancelToken);
      final data = response.data;

      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);

      throw const ParsingException();
    } on DioException catch (error) {
      throw DioExceptionMapper.map(error, requestedDate: requestedDate);
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw ParsingException(cause: error);
    } catch (error) {
      throw ConnectionException(cause: error);
    }
  }
}
