import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../config/app_config.dart';
import 'api_client.dart';
import 'dio_factory.dart';

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
