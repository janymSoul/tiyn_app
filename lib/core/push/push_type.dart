/// Every `data.type` the backend sends (docs/api.md, "What a push contains").
enum PushType {
  taskAssigned('TASK_ASSIGNED'),
  taskSubmitted('TASK_SUBMITTED'),
  taskApproved('TASK_APPROVED'),
  taskRejected('TASK_REJECTED'),
  taskRedoRequested('TASK_REDO_REQUESTED'),
  taskCancelled('TASK_CANCELLED'),
  taskExpired('TASK_EXPIRED'),
  taskExpiredWithPenalty('TASK_EXPIRED_WITH_PENALTY'),
  penaltyApplied('PENALTY_APPLIED'),
  payoutRequested('PAYOUT_REQUESTED'),
  payoutCancelledByTeen('PAYOUT_CANCELLED_BY_TEEN'),
  payoutFulfilled('PAYOUT_FULFILLED'),
  payoutDeclined('PAYOUT_DECLINED'),
  payoutExpired('PAYOUT_EXPIRED'),
  payoutUnlinked('PAYOUT_UNLINKED'),
  familyLinkedTeen('FAMILY_LINKED_TEEN'),
  familyLinkedParent('FAMILY_LINKED_PARENT'),
  familyUnlinked('FAMILY_UNLINKED');

  const PushType(this.wire);

  final String wire;

  /// Null for a type this app version does not know: new backend types must
  /// degrade to "open home", never crash.
  static PushType? fromWire(String? wire) =>
      PushType.values.where((t) => t.wire == wire).firstOrNull;
}
