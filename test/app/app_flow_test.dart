import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';

import '../helpers/pump_app.dart';

class _Auth extends AuthController {
  _Auth(this._user);

  final User? _user;

  @override
  Future<User?> build() async => _user;
}

class _Family extends FamilyController {
  _Family(this._members);

  final List<FamilyMember> _members;

  @override
  Future<List<FamilyMember>> build() async => _members;
}

const _parent = User(
  id: '1',
  role: Role.parent,
  displayName: 'Aigerim',
  joinCode: 'SXVPUR',
);
const _teen = User(id: '2', role: Role.teen, displayName: 'Dana');
const _teenMember = FamilyMember(id: '2', role: Role.teen, displayName: 'Dana');
const _parentMember = FamilyMember(
  id: '1',
  role: Role.parent,
  displayName: 'Aigerim',
);

Future<String> _pump(
  WidgetTester tester, {
  required User? user,
  required List<FamilyMember> family,
}) async {
  await pumpApp(
    tester,
    overrides: [
      authControllerProvider.overrideWith(() => _Auth(user)),
      familyControllerProvider.overrideWith(() => _Family(family)),
    ],
  );
  return routerOf(tester).state.matchedLocation;
}

void main() {
  testWidgets('signed-out user sees the sign-in screen', (tester) async {
    final location = await _pump(tester, user: null, family: const []);
    expect(location, '/sign-in');
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('parent lands on /parent/home with the code and a teen', (
    tester,
  ) async {
    final location = await _pump(
      tester,
      user: _parent,
      family: const [_teenMember],
    );
    expect(location, '/parent/home');
    expect(find.text('SXVPUR'), findsOneWidget);
    expect(find.text('Connect your teen'), findsOneWidget);
    expect(find.text('Dana'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
  });

  testWidgets('unlinked teen lands on join', (tester) async {
    final location = await _pump(tester, user: _teen, family: const []);
    expect(location, '/teen/join');
    expect(find.text("Enter your parent's code"), findsOneWidget);
  });

  testWidgets('linked teen lands on teen home with the 4-item nav', (
    tester,
  ) async {
    final location = await _pump(
      tester,
      user: _teen,
      family: const [_parentMember],
    );
    expect(location, '/teen/home');
    expect(find.text('Connected to Aigerim'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));

    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsOneWidget);
  });

  for (final (locale, text) in const [
    ('ru', 'Продолжить через Google'),
    ('kk', 'Google арқылы жалғастыру'),
  ]) {
    testWidgets('sign-in is shown in $locale', (tester) async {
      await pumpApp(
        tester,
        overrides: [
          authControllerProvider.overrideWith(() => _Auth(null)),
          familyControllerProvider.overrideWith(() => _Family(const [])),
        ],
        locale: Locale(locale),
      );
      expect(find.text(text), findsOneWidget);
    });
  }

  testWidgets('teen tabs: target icon for goals, filled icon when selected', (
    tester,
  ) async {
    await _pump(tester, user: _teen, family: const [_parentMember]);

    expect(find.byIcon(Icons.track_changes), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsNothing);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsNothing);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
  });
}
