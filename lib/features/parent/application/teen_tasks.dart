import 'package:flutter/foundation.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

@immutable
class MilestoneProgress {
  const MilestoneProgress({required this.done, required this.total});

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

/// "2 of 5 done", counted from the children by `milestoneId`. Same rule as the
/// backend's `totalTasks`: cancelled children don't count, approved ones are
/// done.
MilestoneProgress milestoneProgress(String milestoneId, Iterable<Task> tasks) {
  var done = 0;
  var total = 0;
  for (final t in tasks) {
    if (t.milestoneId != milestoneId || t.state == TaskState.cancelled) {
      continue;
    }
    total++;
    if (t.state == TaskState.approved) done++;
  }
  return MilestoneProgress(done: done, total: total);
}

@immutable
class TeenTasks {
  const TeenTasks({
    required this.openTasks,
    required this.finishedTasks,
    required this.openMilestones,
    required this.finishedMilestones,
    required this.progress,
  });

  /// Tasks that are not under a milestone: open ones by deadline.
  final List<Task> openTasks;

  /// Approved, rejected, cancelled and expired, latest first.
  final List<Task> finishedTasks;
  final List<Task> openMilestones;
  final List<Task> finishedMilestones;

  /// Progress of every milestone, by milestone id.
  final Map<String, MilestoneProgress> progress;
}

/// Splits one teen's full history into what each tab shows. A task under a
/// milestone belongs to the Milestones tab (as progress) and is not repeated in
/// Tasks.
TeenTasks groupTeenTasks(List<Task> all) {
  int byDeadline(Task a, Task b) {
    final c = a.deadlineAt.compareTo(b.deadlineAt);
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  DateTime settledAt(Task t) => t.decidedAt ?? t.deadlineAt;
  int latestFirst(Task a, Task b) {
    final c = settledAt(b).compareTo(settledAt(a));
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  List<Task> pick(bool Function(Task) test, {required bool open}) =>
      all.where((t) => test(t) && t.state.isOpen == open).toList()
        ..sort(open ? byDeadline : latestFirst);

  bool plainTask(Task t) => t.kind == TaskKind.task && t.milestoneId == null;
  bool milestone(Task t) => t.kind == TaskKind.milestone;

  return TeenTasks(
    openTasks: pick(plainTask, open: true),
    finishedTasks: pick(plainTask, open: false),
    openMilestones: pick(milestone, open: true),
    finishedMilestones: pick(milestone, open: false),
    progress: {
      for (final m in all.where(milestone)) m.id: milestoneProgress(m.id, all),
    },
  );
}
