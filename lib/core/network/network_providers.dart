import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_token_source.dart';
import '../config/app_config.dart';
import 'api_client.dart';
import 'dio_factory.dart';

/// Overridden by core/auth in step 4 (secure-storage backed implementation).
final sessionTokenSourceProvider = Provider<SessionTokenSource>(
  (ref) => throw UnimplementedError('Provide a SessionTokenSource (step 4)'),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = createDio(
    config: ref.watch(appConfigProvider),
    session: ref.watch(sessionTokenSourceProvider),
  );
  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider =
    Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));
