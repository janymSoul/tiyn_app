import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/application/sign_in_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';

import '../../helpers/pump_app.dart';

class _SignedOut extends AuthController {
  @override
  Future<User?> build() async => null;
}

class _NoFamily extends FamilyController {
  @override
  Future<List<FamilyMember>> build() async => const [];
}

class _Seeded extends SignInController {
  _Seeded(this._seed);

  final SignInState _seed;

  @override
  SignInState build() => _seed;
}

Future<void> _pump(WidgetTester tester, SignInState seed) => pumpApp(
  tester,
  overrides: [
    authControllerProvider.overrideWith(_SignedOut.new),
    familyControllerProvider.overrideWith(_NoFamily.new),
    signInControllerProvider.overrideWith(() => _Seeded(seed)),
  ],
);

void main() {
  testWidgets('the welcome step has no role cards', (tester) async {
    await _pump(tester, Welcome());

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Sign in with your Google account'), findsOneWidget);
    expect(find.text('Teen'), findsNothing);
    expect(find.text('Parent'), findsNothing);
  });

  testWidgets('the role step needs a choice before Continue is enabled', (
    tester,
  ) async {
    await _pump(
      tester,
      ChoosingRole(credential: (idToken: 't', email: 'aigerim@example.com')),
    );

    expect(find.text('Who are you?'), findsOneWidget);
    expect(find.text('Google account: aigerim@example.com'), findsOneWidget);
    expect(find.text('Use a different Google account'), findsOneWidget);

    FilledButton continueButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(continueButton().onPressed, isNull);

    await tester.tap(find.text('Teen'));
    await tester.pumpAndSettle();

    expect(continueButton().onPressed, isNotNull);
  });
}
