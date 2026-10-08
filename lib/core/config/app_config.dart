import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment {
  dev,
  staging,
  prod;

  static AppEnvironment parse(String raw) => switch (raw.trim().toLowerCase()) {
        'dev' => AppEnvironment.dev,
        'staging' => AppEnvironment.staging,
        'prod' || 'production' => AppEnvironment.prod,
        _ => throw ArgumentError.value(
            raw, 'APP_ENV', 'Expected dev, staging or prod'),
      };
}

/// Non-secret, build-time configuration.
///
/// Supplied with `--dart-define-from-file=config/<env>.json`. Nothing here may
/// be a secret: dart-define values can be extracted from the built app.
/// Google Maps SDK keys live in native build config, never in Dart.
final class AppConfig {
  const AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.qrHost,
    required this.qrPathPrefix,
  });

  factory AppConfig.fromEnvironment() => AppConfig.fromValues(
        environment: const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
        apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
        qrHost: const String.fromEnvironment('QR_HOST',
            defaultValue: 'geo.agarwoodglobal.com'),
        qrPathPrefix:
            const String.fromEnvironment('QR_PATH_PREFIX', defaultValue: '/t/'),
      );

  /// Validating constructor (also used by tests).
  factory AppConfig.fromValues({
    required String environment,
    required String apiBaseUrl,
    required String qrHost,
    required String qrPathPrefix,
  }) {
    final env = AppEnvironment.parse(environment);

    final base = Uri.tryParse(apiBaseUrl.trim());
    if (base == null ||
        !base.hasAuthority ||
        (base.scheme != 'https' && base.scheme != 'http')) {
      throw ArgumentError.value(apiBaseUrl, 'API_BASE_URL',
          'Must be an absolute http(s) URL that includes /api/v1');
    }
    if (env != AppEnvironment.dev && base.scheme != 'https') {
      throw ArgumentError.value(
          apiBaseUrl, 'API_BASE_URL', 'staging and prod require https');
    }

    final host = qrHost.trim().toLowerCase();
    if (host.isEmpty || host.contains('/') || host.contains('://')) {
      throw ArgumentError.value(
          qrHost, 'QR_HOST', 'Expected a bare host such as geo.example.com');
    }

    var path = qrPathPrefix.trim();
    if (!path.startsWith('/')) path = '/$path';
    if (!path.endsWith('/')) path = '$path/';

    return AppConfig._(
      environment: env,
      apiBaseUrl: base.toString().replaceAll(RegExp(r'/+$'), ''),
      qrHost: host,
      qrPathPrefix: path,
    );
  }

  final AppEnvironment environment;

  /// Includes `/api/v1`, no trailing slash. Request paths start with `/`.
  final String apiBaseUrl;

  /// Host and path prefix the QR parser accepts (`https://<host><prefix>{token}`).
  final String qrHost;
  final String qrPathPrefix;
}

/// Overridden in `main()` with the validated config.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('Override appConfigProvider in ProviderScope'),
);
