import 'package:dio/dio.dart';

import '../auth/session_token_source.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._session);

  final SessionTokenSource _session;

  /// Set in `Options.extra` for requests that must not carry a token (login).
  static const skipAuthKey = 'skipAuth';
  static const _tokenAttachedKey = '_tokenAttached';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] != true) {
      final token = await _session.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        options.extra[_tokenAttachedKey] = true;
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only a 401 on a request that carried a token means "session expired".
    // A 401 from login just means bad credentials.
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra[_tokenAttachedKey] == true) {
      try {
        await _session.handleUnauthorized();
      } catch (_) {
        // Session cleanup must never mask the original API error.
      }
    }
    handler.next(err);
  }
}
