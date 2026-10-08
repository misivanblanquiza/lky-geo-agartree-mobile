import 'dart:io' show SocketException;

import 'package:dio/dio.dart';

enum ApiFailureKind {
  network,
  timeout,
  cancelled,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  gone,
  validation,
  rateLimited,
  server,
  malformedResponse,
  unknown,
}

/// The single error type feature repositories see from the API layer.
///
/// `toString()` deliberately omits message and body so it is safe to log.
final class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.errorCode,
    this.requestId,
    this.fieldErrors = const {},
    this.retryAfter,
    this.body,
  });

  final ApiFailureKind kind;

  /// Safe to show to the user.
  final String message;
  final int? statusCode;

  /// Backend `error_code`, e.g. `VERSION_CONFLICT`, `QR_REVOKED`.
  final String? errorCode;

  /// Show in support diagnostics.
  final String? requestId;

  /// Laravel `errors` map: field -> messages.
  final Map<String, List<String>> fieldErrors;
  final Duration? retryAfter;

  /// Raw decoded error body for repositories that need extra fields (for
  /// example the tree on a replaced-tag 410). Never log it.
  final Map<String, dynamic>? body;

  static const versionConflictCode = 'VERSION_CONFLICT';
  static const qrRevokedCode = 'QR_REVOKED';

  bool get isVersionConflict => errorCode == versionConflictCode;
  bool get isQrRevoked => errorCode == qrRevokedCode;

  /// Failure class only. Whether a *particular mutation* may be retried is the
  /// sync queue's decision and depends on verified backend replay behavior.
  bool get isTransient => switch (kind) {
        ApiFailureKind.network ||
        ApiFailureKind.timeout ||
        ApiFailureKind.server ||
        ApiFailureKind.rateLimited =>
          true,
        _ => false,
      };

  factory ApiException.malformed({int? statusCode, String? requestId}) =>
      ApiException(
        kind: ApiFailureKind.malformedResponse,
        message: defaultMessage(ApiFailureKind.malformedResponse),
        statusCode: statusCode,
        requestId: requestId,
      );

  /// Tolerates bodies without the `success` flag (framework-level 401/429).
  factory ApiException.fromErrorBody(
    Map<String, dynamic> body, {
    int? statusCode,
    Duration? retryAfter,
  }) {
    final kind = _kindForStatus(statusCode);
    final serverMessage = _string(body['message']);
    return ApiException(
      kind: kind,
      // 5xx messages can leak internals; always use our own copy.
      message: (kind == ApiFailureKind.server || serverMessage == null)
          ? defaultMessage(kind)
          : serverMessage,
      statusCode: statusCode,
      errorCode: _string(body['error_code']),
      requestId: _string(body['request_id']),
      fieldErrors: _fieldErrors(body['errors']),
      retryAfter: retryAfter,
      body: body,
    );
  }

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
            kind: ApiFailureKind.timeout,
            message: defaultMessage(ApiFailureKind.timeout));
      case DioExceptionType.connectionError:
        return ApiException(
            kind: ApiFailureKind.network,
            message: defaultMessage(ApiFailureKind.network));
      case DioExceptionType.badCertificate:
        return const ApiException(
            kind: ApiFailureKind.network,
            message: 'Could not establish a secure connection.');
      case DioExceptionType.cancel:
        return ApiException(
            kind: ApiFailureKind.cancelled,
            message: defaultMessage(ApiFailureKind.cancelled));
      case DioExceptionType.badResponse:
        return _fromResponse(e.response);
      case DioExceptionType.unknown:
        final kind = e.error is SocketException
            ? ApiFailureKind.network
            : ApiFailureKind.unknown;
        return ApiException(kind: kind, message: defaultMessage(kind));
      case DioExceptionType.transformTimeout:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  static ApiException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    final retryAfter = _retryAfter(response?.headers.value('retry-after'));
    final data = response?.data;
    if (data is Map) {
      return ApiException.fromErrorBody(
        data.cast<String, dynamic>(),
        statusCode: status,
        retryAfter: retryAfter,
      );
    }
    final kind = _kindForStatus(status);
    return ApiException(
      kind: kind,
      message: defaultMessage(kind),
      statusCode: status,
      retryAfter: retryAfter,
    );
  }

  static ApiFailureKind _kindForStatus(int? status) => switch (status) {
        401 => ApiFailureKind.unauthorized,
        403 => ApiFailureKind.forbidden,
        404 => ApiFailureKind.notFound,
        409 => ApiFailureKind.conflict,
        410 => ApiFailureKind.gone,
        422 => ApiFailureKind.validation,
        429 => ApiFailureKind.rateLimited,
        final int code when code >= 500 => ApiFailureKind.server,
        _ => ApiFailureKind.unknown,
      };

  static String defaultMessage(ApiFailureKind kind) => switch (kind) {
        ApiFailureKind.network =>
          'No connection. Check your internet and try again.',
        ApiFailureKind.timeout => 'The server took too long to respond. Try again.',
        ApiFailureKind.cancelled => 'The request was cancelled.',
        ApiFailureKind.unauthorized => 'Your session has ended. Sign in again.',
        ApiFailureKind.forbidden => 'You do not have permission to do this.',
        ApiFailureKind.notFound => 'This item could not be found.',
        ApiFailureKind.conflict =>
          'This item was changed elsewhere. Reload and try again.',
        ApiFailureKind.gone => 'This item is no longer available.',
        ApiFailureKind.validation => 'Some details need to be corrected.',
        ApiFailureKind.rateLimited => 'Too many attempts. Wait a moment and try again.',
        ApiFailureKind.server => 'The server had a problem. Try again shortly.',
        ApiFailureKind.malformedResponse =>
          'The server sent a response the app could not read.',
        ApiFailureKind.unknown => 'Something went wrong. Try again.',
      };

  static String? _string(Object? v) => v is String && v.isNotEmpty ? v : null;

  static Duration? _retryAfter(String? raw) {
    final seconds = int.tryParse(raw?.trim() ?? '');
    return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
  }

  static Map<String, List<String>> _fieldErrors(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, List<String>>{};
    raw.forEach((key, value) {
      if (key is! String) return;
      if (value is List) {
        out[key] = value.whereType<String>().toList();
      } else if (value is String) {
        out[key] = [value];
      }
    });
    return out;
  }

  @override
  String toString() =>
      'ApiException(kind: $kind, status: $statusCode, code: $errorCode, requestId: $requestId)';
}
