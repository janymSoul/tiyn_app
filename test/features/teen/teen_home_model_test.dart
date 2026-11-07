import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/features/tasks/application/milestone_progress.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/features/teen/application/teen_home_model.dart';

import '../../helpers/fake_dashboard.dart';

DateTime _d(int day) => DateTime.utc(2026, 12, day, 12);

void main() {
  group('groupDashboard', () {
    test('chores sit under their milestone by milestoneId', () {
      final home = groupDashboard(
        fakeDashboard(
          milestones: [
            fakeMilestone(id: 'm1'),
            fakeMilestone(id: 'm2'),
          ],
          chores: [
            fakeChore(id: 'a', milestoneId: 'm1'),
            fakeChore(id: 'b', milestoneId: 'm2'),
            fakeChore(id: 'c', milestoneId: 'm1'),
            fakeChore(id: 'loose'),
          ],
        ),
      );
      expect(home.chores.map((c) => c.id), ['loose']);
      final byId = {for (final g in home.milestones) g.milestone.id: g};
      expect(byId['m1']!.steps.map((c) => c.id).toSet(), {'a', 'c'});
      expect(byId['m2']!.steps.map((c) => c.id), ['b']);
    });

    test('without milestoneId (older backend) nothing is grouped', () {
      final home = groupDashboard(
        fakeDashboard(
          milestones: [fakeMilestone(id: 'm1')],
          chores: [
            fakeChore(id: 'a'),
            fakeChore(id: 'b'),
          ],
        ),
      );
      expect(home.chores.map((c) => c.id).toSet(), {'a', 'b'});
      expect(home.milestones.single.steps, isEmpty);
    });

    test('a chore whose milestone is not in the response stays visible', () {
      final home = groupDashboard(
        fakeDashboard(
          milestones: [fakeMilestone(id: 'm1')],
          chores: [fakeChore(id: 'orphan', milestoneId: 'old-milestone')],
        ),
      );
      expect(home.chores.map((c) => c.id), ['orphan']);
    });

    test('every chore is shown exactly once', () {
      final dashboard = fakeDashboard(
        milestones: [fakeMilestone(id: 'm1')],
        chores: [
          fakeChore(id: 'a', milestoneId: 'm1'),
          fakeChore(id: 'b', milestoneId: 'gone'),
          fakeChore(id: 'c'),
        ],
      );
      final home = groupDashboard(dashboard);
      final shown = [
        ...home.chores.map((c) => c.id),
        for (final g in home.milestones) ...g.steps.map((c) => c.id),
      ];
      expect(shown..sort(), ['a', 'b', 'c']);
    });

    test('open work comes first by deadline, then what was decided', () {
      final home = groupDashboard(
        fakeDashboard(
          chores: [
            fakeChore(id: 'done', state: TaskState.approved, deadlineAt: _d(1)),
            fakeChore(id: 'late', deadlineAt: _d(20)),
            fakeChore(
              id: 'waiting',
              state: TaskState.submitted,
              deadlineAt: _d(10),
            ),
            fakeChore(id: 'soon', deadlineAt: _d(3)),
            fakeChore(
              id: 'rejected',
              state: TaskState.rejected,
              deadlineAt: _d(5),
            ),
          ],
        ),
      );
      expect(home.chores.map((c) => c.id), [
        'soon',
        'waiting',
        'late',
        'rejected',
        'done',
      ]);
    });

    test('nothing at all is empty', () {
      expect(groupDashboard(fakeDashboard()).isEmpty, isTrue);
      expect(
        groupDashboard(fakeDashboard(chores: [fakeChore()])).isEmpty,
        isFalse,
      );
      expect(
        groupDashboard(fakeDashboard(milestones: [fakeMilestone()])).isEmpty,
        isFalse,
      );
    });
  });

  group('milestone progress', () {
    test('the milestone\'s own counters win when the backend sent them', () {
      // Older approved steps fall out of the dashboard window, so the steps
      // listed here (1) undercount the milestone (4 of 6).
      final home = groupDashboard(
        fakeDashboard(
          milestones: [
            fakeMilestone(id: 'm1', approvedTasks: 4, totalTasks: 6),
          ],
          chores: [fakeChore(id: 'a', milestoneId: 'm1')],
        ),
      );
      expect(
        home.milestones.single.progress,
        const MilestoneProgress(done: 4, total: 6),
      );
    });

    test('without counters it counts the steps it has', () {
      final home = groupDashboard(
        fakeDashboard(
          milestones: [fakeMilestone(id: 'm1')],
          chores: [
            fakeChore(id: 'a', milestoneId: 'm1', state: TaskState.approved),
            fakeChore(id: 'b', milestoneId: 'm1'),
            fakeChore(id: 'c', milestoneId: 'm1', state: TaskState.cancelled),
          ],
        ),
      );
      expect(
        home.milestones.single.progress,
        const MilestoneProgress(done: 1, total: 2),
      );
    });

    test('a milestone with no steps and no counters is 0 of 0', () {
      final home = groupDashboard(fakeDashboard(milestones: [fakeMilestone()]));
      expect(
        home.milestones.single.progress,
        const MilestoneProgress(done: 0, total: 0),
      );
    });

    test('only one counter present falls back to counting', () {
      final home = groupDashboard(
        fakeDashboard(
          milestones: [fakeMilestone(id: 'm1', approvedTasks: 3)],
          chores: [fakeChore(id: 'a', milestoneId: 'm1')],
        ),
      );
      expect(
        home.milestones.single.progress,
        const MilestoneProgress(done: 0, total: 1),
      );
    });
  });
}
