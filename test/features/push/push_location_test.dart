import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/push/push_payload.dart';
import 'package:tiyn_app/core/push/push_type.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/push/application/push_location.dart';

const _teenTaskTypes = {
  PushType.taskAssigned,
  PushType.taskApproved,
  PushType.taskRejected,
  PushType.taskRedoRequested,
  PushType.taskCancelled,
  PushType.taskExpired,
  PushType.taskExpiredWithPenalty,
};

String _home(Role role) => role == Role.parent ? '/parent/home' : '/teen/home';

void main() {
  group('teen', () {
    for (final type in _teenTaskTypes) {
      test('${type.wire} opens the task', () {
        expect(
          pushLocation(PushPayload(type: type, taskId: 't1'), Role.teen),
          '/teen/home/task/t1',
        );
      });
    }

    test('TASK_SUBMITTED is meant for the parent: home', () {
      expect(
        pushLocation(
          const PushPayload(type: PushType.taskSubmitted, taskId: 't1'),
          Role.teen,
        ),
        '/teen/home',
      );
    });
  });

  group('parent', () {
    test('TASK_SUBMITTED opens that review', () {
      expect(
        pushLocation(
          const PushPayload(type: PushType.taskSubmitted, taskId: 't1'),
          Role.parent,
        ),
        '/parent/review/t1',
      );
    });

    for (final type in _teenTaskTypes) {
      test('${type.wire} is meant for the teen: home', () {
        expect(
          pushLocation(PushPayload(type: type, taskId: 't1'), Role.parent),
          '/parent/home',
        );
      });
    }
  });

  group('every type, both roles, with and without ids', () {
    for (final role in Role.values) {
      for (final type in PushType.values) {
        test('${role.name} ${type.wire}', () {
          final withIds = pushLocation(
            PushPayload(type: type, taskId: 't1', payoutId: 'p1'),
            role,
          );
          final without = pushLocation(PushPayload(type: type), role);
          expect(without, _home(role), reason: 'no id -> home');
          final opensTask =
              (role == Role.teen && _teenTaskTypes.contains(type)) ||
              (role == Role.parent && type == PushType.taskSubmitted);
          expect(withIds, opensTask ? isNot(_home(role)) : _home(role));
        });
      }
    }
  });

  test('PAYOUT_*, PENALTY_APPLIED and FAMILY_* go to the role home', () {
    for (final role in Role.values) {
      for (final type in PushType.values.where(
        (t) =>
            t.wire.startsWith('PAYOUT_') ||
            t.wire.startsWith('FAMILY_') ||
            t == PushType.penaltyApplied,
      )) {
        expect(
          pushLocation(
            PushPayload(type: type, taskId: 't1', payoutId: 'p1'),
            role,
          ),
          _home(role),
          reason: '${role.name} ${type.wire}',
        );
      }
    }
  });

  test('an unknown type or no type goes home and never throws', () {
    for (final role in Role.values) {
      expect(pushLocation(const PushPayload(taskId: 't1'), role), _home(role));
      expect(pushLocation(const PushPayload(), role), _home(role));
    }
  });

  test('an id that is not a plain id cannot build a different route', () {
    final location = pushLocation(
      const PushPayload(
        type: PushType.taskApproved,
        taskId: '../../parent/x?y#z',
      ),
      Role.teen,
    );
    expect(Uri.parse(location).pathSegments.length, 4);
    expect(Uri.parse(location).path, startsWith('/teen/home/task/'));
  });
}
