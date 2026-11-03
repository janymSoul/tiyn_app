import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/app/router/router.dart';
import 'package:tiyn_app/design/theme.dart';

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
