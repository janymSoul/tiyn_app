import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';

import '../../helpers/pump_app.dart';

class _Auth extends AuthController {
  _Auth(this._user);

  final User _user;
  int signOutCalls = 0;

  @override
  Future<User?> build() async => _user;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    state = const AsyncData(null);
  }
}

class _Family extends FamilyController {
  _Family(this._load);

  final Future<List<FamilyMember>> Function() _load;

  @override
  Future<List<FamilyMember>> build() => _load();
}

const _teen = User(id: '2', role: Role.teen, displayName: 'Dana');

void main() {
  testWidgets('join screen: Sign out signs out and returns to sign-in', (
    tester,
  ) async {
    final auth = _Auth(_teen);
    await pumpApp(
      tester,
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        familyControllerProvider.overrideWith(() => _Family(() async => [])),
      ],
    );
    expect(routerOf(tester).state.matchedLocation, '/teen/join');
    expect(
      find.text('Wrong account? Sign out and use another Google account.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(auth.signOutCalls, 1);
    expect(routerOf(tester).state.matchedLocation, '/sign-in');
  });

  testWidgets('splash error: Sign out is offered after sign-in and works', (
    tester,
  ) async {
    final auth = _Auth(_teen);
    await pumpApp(
      tester,
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        familyControllerProvider.overrideWith(
          () => _Family(() async => throw StateError('boom')),
        ),
      ],
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(auth.signOutCalls, 1);
    expect(routerOf(tester).state.matchedLocation, '/sign-in');
  });
}
