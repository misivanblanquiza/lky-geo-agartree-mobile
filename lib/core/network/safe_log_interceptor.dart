import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-only. Logs method, redacted path, outcome and duration. Never logs
/// headers, query strings, request/response bodies, or QR tokens.
class SafeLogInterceptor extends Interceptor {
  static const _stopwatchKey = '_stopwatch';
  static final _qrResolveToken = RegExp(r'(/qr/resolve/)[^/?#]+');

  static String redactPath(String path) =>
      path.replaceAllMapped(_qrResolveToken, (m) => '${m[1]}***');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_stopwatchKey] = Stopwatch()..start();
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _log(response.requestOptions, '${response.statusCode}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode?.toString() ?? err.type.name);
    handler.next(err);
  }

  void _log(RequestOptions o, String outcome) {
    final sw = o.extra[_stopwatchKey];
    final ms = sw is Stopwatch ? ' (${sw.elapsedMilliseconds}ms)' : '';
    debugPrint('[api] ${o.method} ${redactPath(o.path)} -> $outcome$ms');
  }
}
