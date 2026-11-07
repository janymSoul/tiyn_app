import 'package:flutter/foundation.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

/// "2 of 5 done". Same rule as the backend's `totalTasks`: cancelled steps
/// don't count, approved ones are done.
@immutable
class MilestoneProgress {
  const MilestoneProgress({required this.done, required this.total});

  factory MilestoneProgress.ofSteps(Iterable<TaskState> steps) {
    var done = 0;
    var total = 0;
    for (final state in steps) {
      if (state == TaskState.cancelled) continue;
      total++;
      if (state == TaskState.approved) done++;
    }
    return MilestoneProgress(done: done, total: total);
  }

  final int done;
  final int total;

  double get fraction => total == 0 ? 0 : done / total;

  @override
  bool operator ==(Object other) =>
      other is MilestoneProgress && other.done == done && other.total == total;

  @override
  int get hashCode => Object.hash(done, total);

  @override
  String toString() => 'MilestoneProgress($done/$total)';
}
