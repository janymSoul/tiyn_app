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

const _parentPayoutTypes = {
  PushType.payoutRequested,
  PushType.payoutCancelledByTeen,
};

const _teenPayoutTypes = {
  PushType.payoutFulfilled,
  PushType.payoutDeclined,
  PushType.payoutExpired,
  PushType.payoutUnlinked,
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

  group('teen payouts', () {
    for (final type in _teenPayoutTypes) {
      test('${type.wire} opens the payout', () {
        expect(
          pushLocation(PushPayload(type: type, payoutId: 'po1'), Role.teen),
          '/teen/home/payout/po1',
        );
      });
    }

    for (final type in _parentPayoutTypes) {
      test('${type.wire} is meant for the parent: home', () {
        expect(
          pushLocation(PushPayload(type: type, payoutId: 'po1'), Role.teen),
          '/teen/home',
        );
      });
    }
  });

  group('parent payouts', () {
    for (final type in _parentPayoutTypes) {
      test('${type.wire} opens the payout', () {
        expect(
          pushLocation(PushPayload(type: type, payoutId: 'po1'), Role.parent),
          '/parent/review/payout/po1',
        );
      });
    }

    for (final type in _teenPayoutTypes) {
      test('${type.wire} is meant for the teen: home', () {
        expect(
          pushLocation(PushPayload(type: type, payoutId: 'po1'), Role.parent),
          '/parent/home',
        );
      });
    }

    test('a blank or missing payoutId goes home', () {
      for (final id in [null, '', '   ']) {
        expect(
          pushLocation(
            PushPayload(type: PushType.payoutRequested, payoutId: id),
            Role.parent,
          ),
          '/parent/home',
        );
      }
    });

    test('a taskId alone does not open a payout', () {
      expect(
        pushLocation(
          const PushPayload(type: PushType.payoutRequested, taskId: 't1'),
          Role.parent,
        ),
        '/parent/home',
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
          final opens =
              (role == Role.teen &&
                  (_teenTaskTypes.contains(type) ||
                      _teenPayoutTypes.contains(type))) ||
              (role == Role.parent &&
                  (type == PushType.taskSubmitted ||
                      _parentPayoutTypes.contains(type)));
          expect(withIds, opens ? isNot(_home(role)) : _home(role));
        });
      }
    }
  });

  test('PENALTY_APPLIED and FAMILY_* go to the role home', () {
    for (final role in Role.values) {
      for (final type in PushType.values.where(
        (t) => t.wire.startsWith('FAMILY_') || t == PushType.penaltyApplied,
      )) {
        expect(
          pushLocation(
            PushPayload(type: type, taskId: 't1', payoutId: 'po1'),
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

  test('a payout id that is not a plain id cannot build another route', () {
    final location = pushLocation(
      const PushPayload(
        type: PushType.payoutRequested,
        payoutId: '../../x?y#z',
      ),
      Role.parent,
    );
    expect(Uri.parse(location).path, startsWith('/parent/review/payout/'));
    expect(Uri.parse(location).pathSegments.length, 4);
  });
}
