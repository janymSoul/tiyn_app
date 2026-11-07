import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/core/push/push_payload.dart';
import 'package:tiyn_app/core/push/push_type.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/parent/application/parent_tabs.dart';
import 'package:tiyn_app/features/tasks/application/task_detail_provider.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';

enum RefreshTarget {
  dashboard,
  family,
  submittedTasks,
  assignedTasks,
  teenTaskLists,
  taskDetail,
}

/// Which data a push makes stale. A push for the other role, or of a type
/// this version does not know, refreshes the role's main lists: never nothing.
Set<RefreshTarget> refreshTargets(PushType? type, Role role) {
  const parentLists = {
    RefreshTarget.submittedTasks,
    RefreshTarget.assignedTasks,
  };
  if (role == Role.teen) {
    return switch (type) {
      PushType.taskAssigned ||
      PushType.taskApproved ||
      PushType.taskRejected ||
      PushType.taskRedoRequested ||
      PushType.taskCancelled ||
      PushType.taskExpired ||
      PushType.taskExpiredWithPenalty => {
        RefreshTarget.dashboard,
        RefreshTarget.taskDetail,
      },
      PushType.penaltyApplied ||
      PushType.payoutFulfilled ||
      PushType.payoutDeclined ||
      PushType.payoutExpired ||
      PushType.payoutUnlinked => {RefreshTarget.dashboard},
      PushType.familyLinkedTeen || PushType.familyUnlinked => {
        RefreshTarget.family,
        RefreshTarget.dashboard,
      },
      _ => {RefreshTarget.dashboard},
    };
  }
  return switch (type) {
    PushType.taskSubmitted => {
      ...parentLists,
      RefreshTarget.teenTaskLists,
      RefreshTarget.taskDetail,
    },
    PushType.payoutRequested || PushType.payoutCancelledByTeen => {},
    PushType.familyLinkedParent || PushType.familyUnlinked => {
      RefreshTarget.family,
      ...parentLists,
      RefreshTarget.teenTaskLists,
    },
    _ => parentLists,
  };
}

/// Applies [refreshTargets] with the silent `refresh()` methods, so the screen
/// keeps its old data and a failed refetch shows nothing. `ref.invalidate`
/// would put the family provider into loading, and the router sends a teen to
/// the splash screen whenever the family is loading.
class PushRefresher {
  PushRefresher(this._ref);

  final Ref _ref;

  void apply(PushPayload payload, Role role) {
    final targets = refreshTargets(payload.type, role);
    for (final target in targets) {
      switch (target) {
        case RefreshTarget.dashboard:
          unawaited(_ref.read(dashboardControllerProvider.notifier).refresh());
        case RefreshTarget.family:
          unawaited(_ref.read(familyControllerProvider.notifier).refresh());
        case RefreshTarget.submittedTasks:
          unawaited(_ref.read(submittedTasksProvider.notifier).refresh());
        case RefreshTarget.assignedTasks:
          unawaited(_ref.read(assignedTasksProvider.notifier).refresh());
        case RefreshTarget.teenTaskLists:
          _refreshTeenLists();
        case RefreshTarget.taskDetail:
          final id = payload.taskId;
          if (id == null) break;
          final detail = taskDetailProvider(id);
          if (_ref.exists(detail)) {
            unawaited(_ref.read(detail.notifier).refresh());
          }
      }
    }
  }

  void _refreshTeenLists() {
    final members = _ref.read(familyControllerProvider).value ?? const [];
    for (final member in members) {
      final list = taskListProvider(TaskQuery.forTeen(member.id));
      if (_ref.exists(list)) unawaited(_ref.read(list.notifier).refresh());
    }
  }
}

final pushRefresherProvider = Provider<PushRefresher>(PushRefresher.new);
