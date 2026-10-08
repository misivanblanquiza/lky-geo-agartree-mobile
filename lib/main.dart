import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Fails fast with a clear message if --dart-define-from-file is missing/invalid.
  final config = AppConfig.fromEnvironment();

  runApp(
    ProviderScope(
      // Riverpod 3 retries failed providers by default. Network failures are
      // handled explicitly (and mutations must never be silently replayed).
      retry: (retryCount, error) => null,
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const GeoAgarTreeApp(),
    ),
  );
}
