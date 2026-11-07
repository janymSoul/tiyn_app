import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiyn_app/app/app.dart';
import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/core/push/firebase_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final config = AppConfig.fromEnvironment();
  await initFirebase();
  runApp(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const TiynApp(),
    ),
  );
}
