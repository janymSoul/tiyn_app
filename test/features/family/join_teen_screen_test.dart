import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';

import '../../helpers/pump_app.dart';

class _Auth extends AuthController {
  @override
  Future<User?> build() async =>
      const User(id: '2', role: Role.teen, displayName: 'Dana');
}

class _Family extends FamilyController {
  final joined = <String>[];
  Object? failWith;

  @override
  Future<List<FamilyMember>> build() async => const [];

  @override
  Future<void> join(String code) async {
    joined.add(code);
    final error = failWith;
    if (error != null) throw error;
  }
}

FilledButton _connect(WidgetTester tester) =>
    tester.widget(find.widgetWithText(FilledButton, 'Connect'));

void main() {
  late _Family family;

  Future<void> pumpJoin(WidgetTester tester) async {
    family = _Family();
    await pumpApp(
      tester,
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        familyControllerProvider.overrideWith(() => family),
      ],
    );
  }

  testWidgets('Connect is disabled until there are 6 characters', (
    tester,
  ) async {
    await pumpJoin(tester);
    expect(_connect(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'SXV');
    await tester.pump();
    expect(_connect(tester).onPressed, isNull);
    expect(family.joined, isEmpty);
  });

  testWidgets('pasting the share message fills the code and joins once', (
    tester,
  ) async {
    await pumpJoin(tester);
    await tester.enterText(
      find.byType(TextField),
      'Join me on Tiyn. My family code is SXVPUR',
    );
    await tester.pumpAndSettle();

    expect(find.text('SXVPUR'), findsOneWidget);
    expect(family.joined, ['SXVPUR']);
  });

  testWidgets('after an error the same code is not submitted again', (
    tester,
  ) async {
    await pumpJoin(tester);
    family.failWith = const ApiException(
      code: 'invalid_join_code',
      statusCode: 404,
    );
    await tester.enterText(find.byType(TextField), 'SXVPUR');
    await tester.pumpAndSettle();
    expect(family.joined, ['SXVPUR']);

    // Tapping the button is an explicit retry.
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(family.joined, ['SXVPUR', 'SXVPUR']);
  });
}
