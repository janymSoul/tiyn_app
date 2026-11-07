import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';

import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';

import '../helpers/fake_dashboard.dart';
import '../helpers/fake_tasks.dart';
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
      taskRepositoryProvider.overrideWithValue(FakeTaskRepository()),
      dashboardRepositoryProvider.overrideWithValue(FakeDashboardRepository()),
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

  testWidgets('parent lands on /parent/home with the teen list', (
    tester,
  ) async {
    final location = await _pump(
      tester,
      user: _parent,
      family: const [_teenMember],
    );
    expect(location, '/parent/home');
    expect(find.text('My teens'), findsOneWidget);
    expect(find.text('Dana'), findsOneWidget);
    expect(find.text('SXVPUR'), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(2));
  });

  testWidgets('unlinked teen lands on join', (tester) async {
    final location = await _pump(tester, user: _teen, family: const []);
    expect(location, '/teen/join');
    expect(find.text("Enter your parent's code"), findsOneWidget);
  });

  testWidgets('linked teen lands on teen home, with no navigation bar', (
    tester,
  ) async {
    final location = await _pump(
      tester,
      user: _teen,
      family: const [_parentMember],
    );
    expect(location, '/teen/home');
    expect(find.text('Hi, Dana'), findsOneWidget);
    expect(find.text('Connected to Aigerim'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('a teen cannot reach the parent screens', (tester) async {
    await _pump(tester, user: _teen, family: const [_parentMember]);
    routerOf(tester).go('/parent/home');
    await tester.pumpAndSettle();
    expect(routerOf(tester).state.matchedLocation, '/teen/home');
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
}
