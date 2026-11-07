import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/features/tasks/application/milestone_progress.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/features/teen/application/milestone_rule.dart';

MilestoneProgress _p(int done, int total) =>
    MilestoneProgress(done: done, total: total);

void main() {
  test('ready only when assigned and every step is approved', () {
    expect(
      milestoneSubmitRule(TaskState.assigned, _p(3, 3)).kind,
      MilestoneSubmitKind.ready,
    );
    expect(milestoneSubmitRule(TaskState.assigned, _p(3, 3)).canSubmit, isTrue);
  });

  test('pending steps block it', () {
    final r = milestoneSubmitRule(TaskState.assigned, _p(2, 3));
    expect(r.kind, MilestoneSubmitKind.stepsPending);
    expect(r.canSubmit, isFalse);
  });

  test('no steps blocks it', () {
    expect(
      milestoneSubmitRule(TaskState.assigned, _p(0, 0)).kind,
      MilestoneSubmitKind.noSteps,
    );
  });

  test('other states have nothing to submit', () {
    for (final s in TaskState.values.where((s) => s != TaskState.assigned)) {
      expect(
        milestoneSubmitRule(s, _p(3, 3)).kind,
        MilestoneSubmitKind.notApplicable,
        reason: '$s',
      );
    }
  });
}
