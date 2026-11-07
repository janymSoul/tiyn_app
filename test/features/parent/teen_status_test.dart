import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/parent/application/teen_status.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

import '../../helpers/fake_tasks.dart';

FamilyMember _teen(String id, String name) =>
    FamilyMember(id: id, role: Role.teen, displayName: name);

void main() {
  group('teenStatus', () {
    test('nothing at all is idle', () {
      expect(
        teenStatus('a', submitted: const [], assigned: const []),
        const TeenStatus(TeenStatusKind.idle),
      );
    });

    test('assigned tasks are "active"', () {
      final status = teenStatus(
        'a',
        submitted: const [],
        assigned: [
          fakeTask(id: '1', teenId: 'a'),
          fakeTask(id: '2', teenId: 'a'),
          fakeTask(id: '3', teenId: 'a'),
        ],
      );
      expect(status, const TeenStatus(TeenStatusKind.active, 3));
    });

    test('anything submitted wins over active work', () {
      final status = teenStatus(
        'a',
        submitted: [
          fakeTask(id: '1', teenId: 'a', state: TaskState.submitted),
          fakeTask(id: '2', teenId: 'a', state: TaskState.submitted),
        ],
        assigned: [fakeTask(id: '3', teenId: 'a')],
      );
      expect(status, const TeenStatus(TeenStatusKind.toCheck, 2));
    });

    test('other teens\' tasks are ignored', () {
      final status = teenStatus(
        'a',
        submitted: [fakeTask(teenId: 'b', state: TaskState.submitted)],
        assigned: [fakeTask(id: '2', teenId: 'b')],
      );
      expect(status.kind, TeenStatusKind.idle);
    });

    test('a submitted milestone counts as something to check', () {
      final status = teenStatus(
        'a',
        submitted: [
          fakeTask(
            teenId: 'a',
            kind: TaskKind.milestone,
            state: TaskState.submitted,
          ),
        ],
        assigned: const [],
      );
      expect(status, const TeenStatus(TeenStatusKind.toCheck, 1));
    });

    test('a milestone is not counted on top of its open steps', () {
      final status = teenStatus(
        'a',
        submitted: const [],
        assigned: [
          fakeTask(id: 'm', teenId: 'a', kind: TaskKind.milestone),
          fakeTask(id: '1', teenId: 'a', milestoneId: 'm'),
          fakeTask(id: '2', teenId: 'a', milestoneId: 'm'),
        ],
      );
      expect(status, const TeenStatus(TeenStatusKind.active, 2));
    });

    test('a milestone with no open step is still work to do', () {
      final status = teenStatus(
        'a',
        submitted: const [],
        assigned: [fakeTask(id: 'm', teenId: 'a', kind: TaskKind.milestone)],
      );
      expect(status, const TeenStatus(TeenStatusKind.active, 1));
    });
  });

  group('teenOverview', () {
    test('teens with something to check come first, then by name', () {
      final rows = teenOverview(
        [_teen('1', 'Madina'), _teen('2', 'Dana'), _teen('3', 'Aibek')],
        submitted: [fakeTask(id: 's', teenId: '1', state: TaskState.submitted)],
        assigned: [fakeTask(id: 'a', teenId: '3')],
      );
      expect(rows.map((r) => r.teen.displayName), ['Madina', 'Aibek', 'Dana']);
      expect(rows.map((r) => r.status!.kind), [
        TeenStatusKind.toCheck,
        TeenStatusKind.active,
        TeenStatusKind.idle,
      ]);
    });

    test('several teens to check are ordered by name among themselves', () {
      final rows = teenOverview(
        [_teen('1', 'Zhan'), _teen('2', 'Aibek'), _teen('3', 'Dana')],
        submitted: [
          fakeTask(id: 's1', teenId: '1', state: TaskState.submitted),
          fakeTask(id: 's2', teenId: '2', state: TaskState.submitted),
        ],
        assigned: const [],
      );
      expect(rows.map((r) => r.teen.displayName), ['Aibek', 'Zhan', 'Dana']);
    });

    test('names sort case-insensitively, ties by id', () {
      final rows = teenOverview(
        [_teen('2', 'dana'), _teen('1', 'Dana'), _teen('3', 'Aibek')],
        submitted: const [],
        assigned: const [],
      );
      expect(rows.map((r) => r.teen.id), ['3', '1', '2']);
    });

    test('until both lists are loaded there is no status, only name order', () {
      final teens = [_teen('1', 'Madina'), _teen('2', 'Dana')];
      for (final rows in [
        teenOverview(teens, submitted: null, assigned: const []),
        teenOverview(teens, submitted: const [], assigned: null),
        teenOverview(teens, submitted: null, assigned: null),
      ]) {
        expect(rows.map((r) => r.teen.displayName), ['Dana', 'Madina']);
        expect(rows.every((r) => r.status == null), isTrue);
      }
    });
  });
}
