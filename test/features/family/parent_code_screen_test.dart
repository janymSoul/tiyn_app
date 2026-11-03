import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/family/data/family_repository.dart';

import '../../helpers/pump_app.dart';

class _Auth extends AuthController {
  @override
  Future<User?> build() async => const User(
    id: '1',
    role: Role.parent,
    displayName: 'Aigerim',
    joinCode: 'SXVPUR',
  );
}

class _Repository implements FamilyRepository {
  final teens = <FamilyMember>[];
  int calls = 0;

  @override
  Future<List<FamilyMember>> members() async {
    calls++;
    return List.of(teens);
  }

  @override
  Future<FamilyMember> join(String code) => throw UnimplementedError();
}

void main() {
  testWidgets('coming back to the app shows a teen who joined meanwhile', (
    tester,
  ) async {
    final repository = _Repository();
    await pumpApp(
      tester,
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        familyRepositoryProvider.overrideWithValue(repository),
      ],
    );
    expect(repository.calls, 1);
    expect(find.text('Dana'), findsNothing);

    // The parent leaves to send the code; the teen joins in the meantime.
    repository.teens.add(
      const FamilyMember(id: '2', role: Role.teen, displayName: 'Dana'),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(
      repository.calls,
      1,
      reason: 'going to the background must not fetch',
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(repository.calls, 2, reason: 'exactly one refetch on resume');
    expect(find.text('Dana'), findsOneWidget);
  });
}
