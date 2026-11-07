import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/payouts/application/payout_providers.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';

import 'fake_family.dart';
import 'fake_payouts.dart';
import 'fake_tasks.dart';

class _ParentAuth extends AuthController {
  @override
  Future<User?> build() async => const User(
    id: 'parent1',
    role: Role.parent,
    displayName: 'Aigerim',
    joinCode: 'SXVPUR',
  );
}

/// A signed-in parent with fake family and task backends.
class ParentHarness {
  ParentHarness({List<({String id, String name})> teens = const []})
    : family = FakeFamilyRepository([
        for (final t in teens) teenMember(t.id, t.name),
      ]),
      tasks = FakeTaskRepository(),
      payouts = FakePayoutRepository();

  final FakeFamilyRepository family;
  final FakeTaskRepository tasks;
  final FakePayoutRepository payouts;

  List<Override> get overrides => [
    authControllerProvider.overrideWith(_ParentAuth.new),
    familyRepositoryProvider.overrideWithValue(family),
    taskRepositoryProvider.overrideWithValue(tasks),
    payoutRepositoryProvider.overrideWithValue(payouts),
  ];
}
