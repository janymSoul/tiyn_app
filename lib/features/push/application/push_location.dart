import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/push/push_payload.dart';
import 'package:tiyn_app/core/push/push_type.dart';
import 'package:tiyn_app/core/session/role.dart';

/// Where a tapped push goes. Pure and total: an unknown type, a missing or
/// blank id or a type meant for the other role all land on the role's home,
/// and nothing here throws. Task types read `taskId`, payout types `payoutId`.
String pushLocation(PushPayload payload, Role role) {
  final home = role == Role.parent ? Routes.parentHome : Routes.teenHome;
  final taskId = _usable(payload.taskId);
  final payoutId = _usable(payload.payoutId);
  return switch ((role, payload.type)) {
    (Role.parent, PushType.taskSubmitted) when taskId != null =>
      Routes.parentReviewTask(taskId),
    (
      Role.teen,
      PushType.taskAssigned ||
          PushType.taskApproved ||
          PushType.taskRejected ||
          PushType.taskRedoRequested ||
          PushType.taskCancelled ||
          PushType.taskExpired ||
          PushType.taskExpiredWithPenalty,
    )
        when taskId != null =>
      Routes.teenTask(taskId),
    (Role.parent, PushType.payoutRequested || PushType.payoutCancelledByTeen)
        when payoutId != null =>
      Routes.parentPayout(payoutId),
    (
      Role.teen,
      PushType.payoutFulfilled ||
          PushType.payoutDeclined ||
          PushType.payoutExpired ||
          PushType.payoutUnlinked,
    )
        when payoutId != null =>
      Routes.teenPayout(payoutId),
    _ => home,
  };
}

/// The encoded id, or null when it is missing or blank.
String? _usable(String? id) {
  if (id == null || id.trim().isEmpty) return null;
  return Uri.encodeComponent(id);
}
