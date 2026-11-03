import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/app/app.dart';
import 'package:tiyn_app/app/router/router.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides,
      child: TiynApp(locale: locale),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter routerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(TiynApp)))
        .read(routerProvider);
