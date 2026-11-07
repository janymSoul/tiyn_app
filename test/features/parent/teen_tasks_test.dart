import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/features/parent/application/teen_tasks.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

import '../../helpers/fake_tasks.dart';

DateTime _d(int day) => DateTime.utc(2026, 11, day, 12);

void main() {
  group('groupTeenTasks', () {
    test('tasks and milestones go to their own tabs', () {
      final g = groupTeenTasks([
        fakeTask(id: 't'),
        fakeTask(id: 'm', kind: TaskKind.milestone),
      ]);
      expect(g.openTasks.map((t) => t.id), ['t']);
      expect(g.openMilestones.map((t) => t.id), ['m']);
    });

    test('a task under a milestone is not repeated in Tasks', () {
      final g = groupTeenTasks([
        fakeTask(id: 'm', kind: TaskKind.milestone),
        fakeTask(id: 'child', milestoneId: 'm'),
        fakeTask(id: 'plain'),
      ]);
      expect(g.openTasks.map((t) => t.id), ['plain']);
      expect(g.finishedTasks, isEmpty);
    });

    test('open tasks are ordered by deadline', () {
      final g = groupTeenTasks([
        fakeTask(id: 'late', deadlineAt: _d(20)),
        fakeTask(id: 'soon', deadlineAt: _d(9)),
        fakeTask(
          id: 'submitted',
          state: TaskState.submitted,
          deadlineAt: _d(12),
        ),
      ]);
      expect(g.openTasks.map((t) => t.id), ['soon', 'submitted', 'late']);
    });

    test('assigned and submitted are open; the rest is finished', () {
      final g = groupTeenTasks([
        for (final s in TaskState.values) fakeTask(id: s.wire, state: s),
      ]);
      expect(g.openTasks.map((t) => t.id).toSet(), {'ASSIGNED', 'SUBMITTED'});
      expect(g.finishedTasks.map((t) => t.id).toSet(), {
        'APPROVED',
        'REJECTED',
        'CANCELLED',
        'EXPIRED',
      });
    });

    test('finished milestones are split off the same way', () {
      final g = groupTeenTasks([
        fakeTask(id: 'open', kind: TaskKind.milestone),
        fakeTask(
          id: 'done',
          kind: TaskKind.milestone,
          state: TaskState.approved,
        ),
      ]);
      expect(g.openMilestones.map((t) => t.id), ['open']);
      expect(g.finishedMilestones.map((t) => t.id), ['done']);
    });

    test('finished tasks come latest first', () {
      final g = groupTeenTasks([
        fakeTask(id: 'old', state: TaskState.approved, deadlineAt: _d(2)),
        fakeTask(id: 'new', state: TaskState.rejected, deadlineAt: _d(5)),
      ]);
      expect(g.finishedTasks.map((t) => t.id), ['new', 'old']);
    });

    test('no tasks at all is all empty', () {
      final g = groupTeenTasks(const []);
      expect(g.openTasks, isEmpty);
      expect(g.finishedTasks, isEmpty);
      expect(g.openMilestones, isEmpty);
      expect(g.finishedMilestones, isEmpty);
      expect(g.progress, isEmpty);
    });
  });

  group('milestoneProgress', () {
    test('counts approved children against all children', () {
      final tasks = [
        fakeTask(id: 'm', kind: TaskKind.milestone),
        fakeTask(id: '1', milestoneId: 'm', state: TaskState.approved),
        fakeTask(id: '2', milestoneId: 'm', state: TaskState.approved),
        fakeTask(id: '3', milestoneId: 'm', state: TaskState.submitted),
        fakeTask(id: '4', milestoneId: 'm'),
        fakeTask(id: '5', milestoneId: 'm', state: TaskState.rejected),
      ];
      expect(
        milestoneProgress('m', tasks),
        const MilestoneProgress(done: 2, total: 5),
      );
    });

    test('cancelled children do not count at all (as on the backend)', () {
      final tasks = [
        fakeTask(id: '1', milestoneId: 'm', state: TaskState.approved),
        fakeTask(id: '2', milestoneId: 'm', state: TaskState.cancelled),
      ];
      expect(
        milestoneProgress('m', tasks),
        const MilestoneProgress(done: 1, total: 1),
      );
    });

    test('other milestones\' children are ignored', () {
      final tasks = [
        fakeTask(id: '1', milestoneId: 'other', state: TaskState.approved),
        fakeTask(id: '2'),
      ];
      expect(
        milestoneProgress('m', tasks),
        const MilestoneProgress(done: 0, total: 0),
      );
    });

    test('fraction is 0 for a milestone without tasks', () {
      expect(const MilestoneProgress(done: 0, total: 0).fraction, 0);
      expect(const MilestoneProgress(done: 1, total: 4).fraction, 0.25);
    });

    test('groupTeenTasks carries progress for every milestone', () {
      final g = groupTeenTasks([
        fakeTask(id: 'm1', kind: TaskKind.milestone),
        fakeTask(id: 'm2', kind: TaskKind.milestone, state: TaskState.approved),
        fakeTask(id: 'c', milestoneId: 'm1', state: TaskState.approved),
      ]);
      expect(g.progress['m1'], const MilestoneProgress(done: 1, total: 1));
      expect(g.progress['m2'], const MilestoneProgress(done: 0, total: 0));
    });
  });
}
