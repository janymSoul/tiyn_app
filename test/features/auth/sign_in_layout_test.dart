import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';

import '../../helpers/pump_app.dart';

class _SignedOut extends AuthController {
  @override
  Future<User?> build() async => null;
}

void main() {
  for (final locale in const ['ru', 'kk']) {
    testWidgets('sign-in does not overflow in $locale at 360x640, 1.3x text', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(360, 640)
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearAllTestValues();
      });

      await pumpApp(
        tester,
        overrides: [authControllerProvider.overrideWith(_SignedOut.new)],
        locale: Locale(locale),
      );

      expect(find.byType(FilledButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
