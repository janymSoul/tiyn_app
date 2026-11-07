import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/push/push_type.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/push/application/push_refresh.dart';

void main() {
  test(
    'every type, in every role, refreshes something or is a known no-op',
    () {
      for (final role in Role.values) {
        for (final type in [...PushType.values, null]) {
          final targets = refreshTargets(type, role);
          final knownNoOp =
              role == Role.parent &&
              (type == PushType.payoutRequested ||
                  type == PushType.payoutCancelledByTeen);
          expect(
            targets.isNotEmpty || knownNoOp,
            isTrue,
            reason: '${role.name} ${type?.wire}',
          );
        }
      }
    },
  );

  test('a teen task push refreshes the dashboard and that task', () {
    expect(refreshTargets(PushType.taskApproved, Role.teen), {
      RefreshTarget.dashboard,
      RefreshTarget.taskDetail,
    });
  });

  test('money pushes refresh the teen dashboard', () {
    for (final type in [PushType.penaltyApplied, PushType.payoutFulfilled]) {
      expect(refreshTargets(type, Role.teen), {RefreshTarget.dashboard});
    }
  });

  test(
    'a submitted task refreshes the parent lists, teen lists and detail',
    () {
      expect(refreshTargets(PushType.taskSubmitted, Role.parent), {
        RefreshTarget.submittedTasks,
        RefreshTarget.assignedTasks,
        RefreshTarget.teenTaskLists,
        RefreshTarget.taskDetail,
      });
    },
  );

  test('family pushes refresh the family first', () {
    expect(
      refreshTargets(PushType.familyUnlinked, Role.teen),
      contains(RefreshTarget.family),
    );
    expect(
      refreshTargets(PushType.familyLinkedParent, Role.parent),
      contains(RefreshTarget.family),
    );
  });

  test('an unknown type or the other role refreshes the main lists', () {
    expect(refreshTargets(null, Role.teen), {RefreshTarget.dashboard});
    expect(refreshTargets(null, Role.parent), {
      RefreshTarget.submittedTasks,
      RefreshTarget.assignedTasks,
    });
    expect(refreshTargets(PushType.taskSubmitted, Role.teen), {
      RefreshTarget.dashboard,
    });
  });
}
