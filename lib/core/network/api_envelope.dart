import 'api_exception.dart';

final class ApiMeta {
  const ApiMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  static ApiMeta? tryParse(Object? json) {
    if (json is! Map) return null;
    int? asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v');
    final current = asInt(json['current_page']);
    final perPage = asInt(json['per_page']);
    final total = asInt(json['total']);
    final last = asInt(json['last_page']);
    if (current == null || perPage == null || total == null || last == null) {
      return null;
    }
    return ApiMeta(
        currentPage: current, perPage: perPage, total: total, lastPage: last);
  }
}

/// `{ success, data, message?, request_id?, meta? }`, parsed in one place.
final class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.data,
    this.message,
    this.requestId,
    this.meta,
  });

  final T data;
  final String? message;
  final String? requestId;
  final ApiMeta? meta;

  /// Throws [ApiException] for error envelopes and unreadable bodies.
  ///
  /// [decode] receives the raw `data` value (a missing key arrives as `null`).
  /// Any exception it throws becomes `malformedResponse`; the original is
  /// dropped on purpose because decode errors can echo payload content.
  factory ApiEnvelope.fromBody(
    Object? body, {
    required int? statusCode,
    required T Function(Object? data) decode,
  }) {
    if (body is! Map) throw ApiException.malformed(statusCode: statusCode);
    final map = body.cast<String, dynamic>();
    if (map['success'] != true) {
      throw ApiException.fromErrorBody(map, statusCode: statusCode);
    }
    final requestId = map['request_id'] is String ? map['request_id'] as String : null;
    try {
      return ApiEnvelope<T>(
        data: decode(map['data']),
        message: map['message'] is String ? map['message'] as String : null,
        requestId: requestId,
        meta: ApiMeta.tryParse(map['meta']),
      );
    } on Object {
      throw ApiException.malformed(statusCode: statusCode, requestId: requestId);
    }
  }
}
