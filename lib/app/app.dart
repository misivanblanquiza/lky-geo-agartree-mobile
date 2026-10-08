import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import 'theme/app_theme.dart';

class GeoAgarTreeApp extends StatelessWidget {
  const GeoAgarTreeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'GeoAgarTree',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _FoundationPlaceholder(),
      );
}

/// Replaced by the go_router shell in step 5.
class _FoundationPlaceholder extends ConsumerWidget {
  const _FoundationPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appConfigProvider).environment;
    return Scaffold(body: Center(child: Text('GeoAgarTree · ${env.name}')));
  }
}
