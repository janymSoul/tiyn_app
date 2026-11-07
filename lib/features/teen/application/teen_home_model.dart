import 'package:flutter/foundation.dart';
import 'package:tiyn_app/features/tasks/application/milestone_progress.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';

@immutable
class MilestoneGroup {
  const MilestoneGroup({
    required this.milestone,
    required this.steps,
    required this.progress,
  });

  final DashboardTask milestone;

  /// The chores that point at this milestone, in the order to show them.
  final List<DashboardTask> steps;
  final MilestoneProgress progress;
}

@immutable
class TeenHome {
  const TeenHome({required this.chores, required this.milestones});

  /// Chores that belong to no milestone shown here.
  final List<DashboardTask> chores;
  final List<MilestoneGroup> milestones;

  bool get isEmpty => chores.isEmpty && milestones.isEmpty;
}

/// Groups the dashboard chores under their milestone by `milestoneId`.
///
/// A chore stays in the plain list when it has no `milestoneId` (older
/// backend, or no milestone) or when its milestone is not in this response
/// (the dashboard only returns recent work). Nothing is ever dropped.
TeenHome groupDashboard(Dashboard dashboard) {
  final milestoneIds = {for (final m in dashboard.milestones) m.id};
  final stepsOf = <String, List<DashboardTask>>{};
  final plain = <DashboardTask>[];
  for (final chore in dashboard.chores) {
    final parent = chore.milestoneId;
    if (parent != null && milestoneIds.contains(parent)) {
      stepsOf.putIfAbsent(parent, () => []).add(chore);
    } else {
      plain.add(chore);
    }
  }

  return TeenHome(
    chores: _openFirst(plain),
    milestones: [
      for (final m in _openFirst(dashboard.milestones))
        MilestoneGroup(
          milestone: m,
          steps: _openFirst(stepsOf[m.id] ?? const []),
          progress: _progressOf(m, stepsOf[m.id] ?? const []),
        ),
    ],
  );
}

/// The milestone's own counters when the backend sent them, because the
/// dashboard window may not include its older approved steps; else what is
/// here.
MilestoneProgress _progressOf(DashboardTask m, List<DashboardTask> steps) {
  final approved = m.approvedTasks;
  final total = m.totalTasks;
  if (approved != null && total != null) {
    return MilestoneProgress(done: approved, total: total);
  }
  return MilestoneProgress.ofSteps(steps.map((s) => s.state));
}

/// Open work first, by deadline; then what was decided recently, latest
/// deadline first.
List<DashboardTask> _openFirst(List<DashboardTask> tasks) {
  final open = tasks.where((t) => t.state.isOpen).toList()
    ..sort((a, b) {
      final c = a.deadlineAt.compareTo(b.deadlineAt);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  final decided = tasks.where((t) => !t.state.isOpen).toList()
    ..sort((a, b) {
      final c = b.deadlineAt.compareTo(a.deadlineAt);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  return [...open, ...decided];
}
