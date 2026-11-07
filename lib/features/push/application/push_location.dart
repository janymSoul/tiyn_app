import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/push/push_payload.dart';
import 'package:tiyn_app/core/push/push_type.dart';
import 'package:tiyn_app/core/session/role.dart';

/// Where a tapped push goes. Pure and total: an unknown type, a missing id or
/// a type meant for the other role all land on the role's home, and nothing
/// here throws. Payout screens arrive in Phase 2b, which remaps `PAYOUT_*`.
String pushLocation(PushPayload payload, Role role) {
  final home = role == Role.parent ? Routes.parentHome : Routes.teenHome;
  final taskId = payload.taskId;
  if (taskId == null) return home;
  final id = Uri.encodeComponent(taskId);
  return switch ((role, payload.type)) {
    (Role.parent, PushType.taskSubmitted) => Routes.parentReviewTask(id),
    (
      Role.teen,
      PushType.taskAssigned ||
          PushType.taskApproved ||
          PushType.taskRejected ||
          PushType.taskRedoRequested ||
          PushType.taskCancelled ||
          PushType.taskExpired ||
          PushType.taskExpiredWithPenalty,
    ) =>
      Routes.teenTask(id),
    _ => home,
  };
}
