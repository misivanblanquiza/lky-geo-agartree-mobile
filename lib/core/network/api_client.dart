import 'package:dio/dio.dart';

import 'api_envelope.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

typedef ApiDecoder<T> = T Function(Object? data);

/// Thin wrapper over Dio: every call returns a parsed [ApiEnvelope] or throws
/// an [ApiException]. Feature data sources never see `DioException`.
class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  /// Pass as `options` for requests that must not send a token (login).
  static Options get unauthenticated =>
      Options(extra: {AuthInterceptor.skipAuthKey: true});

  Future<ApiEnvelope<T>> get<T>(
    String path, {
    required ApiDecoder<T> decode,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _send('GET', path,
          decode: decode, query: query, options: options, cancelToken: cancelToken);

  Future<ApiEnvelope<T>> post<T>(
    String path, {
    required ApiDecoder<T> decode,
    Object? body,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) =>
      _send('POST', path,
          decode: decode,
          body: body,
          query: query,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress);

  Future<ApiEnvelope<T>> patch<T>(
    String path, {
    required ApiDecoder<T> decode,
    Object? body,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _send('PATCH', path,
          decode: decode, body: body, options: options, cancelToken: cancelToken);

  Future<ApiEnvelope<T>> _send<T>(
    String method,
    String path, {
    required ApiDecoder<T> decode,
    Object? body,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final Response<Object?> response;
    try {
      response = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: (options ?? Options()).copyWith(method: method),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
    return ApiEnvelope<T>.fromBody(
      response.data,
      statusCode: response.statusCode,
      decode: decode,
    );
  }
}
