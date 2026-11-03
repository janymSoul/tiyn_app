import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/app/app.dart';
import 'package:tiyn_app/app/config.dart';

void main() {
  final config = AppConfig.fromEnvironment();
  runApp(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const TiynApp(),
    ),
  );
}
