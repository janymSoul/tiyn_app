import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/config.dart';
import 'core/theme.dart';
import 'router.dart';

void main() {
  final config = AppConfig.fromEnvironment();
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const TiynApp(),
    ),
  );
}

class TiynApp extends ConsumerWidget {
  const TiynApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'tiyn',
      theme: buildTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
