import 'package:tiyn_app/features/tasks/application/milestone_progress.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

enum MilestoneSubmitKind {
  /// Nothing to submit: it is not waiting for the teen (already sent, decided).
  notApplicable,
  noSteps,
  stepsPending,
  ready,
}

class MilestoneSubmitRule {
  const MilestoneSubmitRule(this.kind, this.progress);

  final MilestoneSubmitKind kind;
  final MilestoneProgress progress;

  bool get canSubmit => kind == MilestoneSubmitKind.ready;
}

/// The app-side rule (the backend does not enforce it): a milestone can be
/// submitted only while `ASSIGNED`, with at least one step, and only when
/// every step is `APPROVED`.
MilestoneSubmitRule milestoneSubmitRule(
  TaskState state,
  MilestoneProgress progress,
) {
  final kind = switch (state) {
    TaskState.assigned when progress.total == 0 => MilestoneSubmitKind.noSteps,
    TaskState.assigned when progress.done < progress.total =>
      MilestoneSubmitKind.stepsPending,
    TaskState.assigned => MilestoneSubmitKind.ready,
    _ => MilestoneSubmitKind.notApplicable,
  };
  return MilestoneSubmitRule(kind, progress);
}
