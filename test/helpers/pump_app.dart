import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiyn_app/app/app.dart';
import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/app/router/router.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) async {
  // Bundled Rubik only; tests must never reach the network for fonts.
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            flavor: Flavor.staging,
            apiBaseUrl: Uri.parse('https://api.test'),
            googleServerClientId: null,
          ),
        ),
        ...overrides,
      ],
      child: TiynApp(locale: locale),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter routerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(TiynApp)))
        .read(routerProvider);
