import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/session_token_source.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';
import 'safe_log_interceptor.dart';

Dio createDio({
  required AppConfig config,
  required SessionTokenSource session,
  bool enableLogging = kDebugMode,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      // Without Accept: application/json, Laravel may answer validation and
      // auth failures with redirects/HTML instead of the JSON envelope.
      headers: {Headers.acceptHeader: Headers.jsonContentType},
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.add(AuthInterceptor(session));
  if (enableLogging) dio.interceptors.add(SafeLogInterceptor());
  return dio;
}
