import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/push/push_type.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/push/application/push_refresh.dart';

void main() {
  test('every type, in every role, refreshes something', () {
    for (final role in Role.values) {
      for (final type in [...PushType.values, null]) {
        final targets = refreshTargets(type, role);
        expect(
          targets.isNotEmpty,
          isTrue,
          reason: '${role.name} ${type?.wire}',
        );
      }
    }
  });

  test('a teen task push refreshes the dashboard and that task', () {
    expect(refreshTargets(PushType.taskApproved, Role.teen), {
      RefreshTarget.dashboard,
      RefreshTarget.taskDetail,
    });
  });

  test('money pushes refresh the teen dashboard', () {
    expect(refreshTargets(PushType.penaltyApplied, Role.teen), {
      RefreshTarget.dashboard,
    });
  });

  test('a teen payout outcome refreshes the dashboard and that payout', () {
    for (final type in [
      PushType.payoutFulfilled,
      PushType.payoutDeclined,
      PushType.payoutExpired,
      PushType.payoutUnlinked,
    ]) {
      expect(refreshTargets(type, Role.teen), {
        RefreshTarget.dashboard,
        RefreshTarget.payoutDetail,
      }, reason: type.wire);
    }
  });

  test('a parent payout push refreshes the requests and that payout', () {
    for (final type in [
      PushType.payoutRequested,
      PushType.payoutCancelledByTeen,
    ]) {
      expect(refreshTargets(type, Role.parent), {
        RefreshTarget.requestedPayouts,
        RefreshTarget.payoutDetail,
      }, reason: type.wire);
    }
  });

  test('a parent unlink also refreshes the requests', () {
    expect(
      refreshTargets(PushType.familyUnlinked, Role.parent),
      contains(RefreshTarget.requestedPayouts),
    );
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
      RefreshTarget.requestedPayouts,
    });
    expect(refreshTargets(PushType.taskSubmitted, Role.teen), {
      RefreshTarget.dashboard,
    });
  });
}
