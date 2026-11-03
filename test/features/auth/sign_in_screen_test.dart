import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/session/role.dart';
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

  testWidgets('role cards are one labelled, selectable semantics node each', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      ChoosingRole(
        credential: (idToken: 't', email: 'aigerim@example.com'),
        selected: Role.parent,
      ),
    );

    final teen = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'^Teen\. ')),
    );
    final parent = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'^Parent\. ')),
    );
    for (final node in [teen, parent]) {
      final flags = node.getSemanticsData().flagsCollection;
      expect(flags.isButton, isTrue);
      expect(flags.isInMutuallyExclusiveGroup, isTrue);
    }
    expect(
      teen.getSemanticsData().flagsCollection.isChecked,
      isNot(CheckedState.isTrue),
    );
    expect(
      parent.getSemanticsData().flagsCollection.isChecked,
      CheckedState.isTrue,
    );
    // The visible texts are excluded, so the label is not read twice.
    expect(find.bySemanticsLabel('Teen'), findsNothing);
    handle.dispose();
  });

  testWidgets('role cards ripple: Material ancestor and an InkWell', (
    tester,
  ) async {
    await _pump(
      tester,
      ChoosingRole(credential: (idToken: 't', email: 'aigerim@example.com')),
    );
    final card = find.ancestor(
      of: find.text('Teen'),
      matching: find.byType(InkWell),
    );
    expect(card, findsOneWidget);
    expect(
      find.ancestor(of: card, matching: find.byType(Material)),
      findsWidgets,
    );
  });

  testWidgets('the Google button shows the logo asset', (tester) async {
    await _pump(tester, Welcome());
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, 'assets/images/google_g.png');
  });
}
