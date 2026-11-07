import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

import '../../helpers/fake_tasks.dart';
import '../../helpers/parent_harness.dart';
import '../../helpers/pump_app.dart';

const _dana = (id: 'teen1', name: 'Dana');

Future<void> _open(
  WidgetTester tester,
  ParentHarness h,
  String taskTitle,
) async {
  await pumpApp(tester, overrides: h.overrides);
  await tester.tap(find.text('Dana'));
  await tester.pumpAndSettle();
  // Finished tasks sit in a collapsed group.
  final finished = find.textContaining('Finished (');
  if (finished.evaluate().isNotEmpty) {
    await tester.tap(finished);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text(taskTitle));
  await tester.pumpAndSettle();
}

void main() {
  group('cancel is offered only while the task is open', () {
    for (final entry in {
      TaskState.assigned: true,
      TaskState.submitted: true,
      TaskState.approved: false,
      TaskState.rejected: false,
      TaskState.cancelled: false,
      TaskState.expired: false,
    }.entries) {
      testWidgets('${entry.key.wire}: ${entry.value}', (tester) async {
        final h = ParentHarness(teens: [_dana]);
        h.tasks.tasks = [fakeTask(id: 't1', state: entry.key)];
        await _open(tester, h, 'Wash dishes');
        expect(
          find.text('Cancel task'),
          entry.value ? findsOneWidget : findsNothing,
        );
      });
    }
  });

  testWidgets('a task row opens its detail with the teen name', (tester) async {
    final h = ParentHarness(teens: [_dana]);
    h.tasks.tasks = [
      fakeTask(id: 't1')
          .copyWith(description: 'With soap', decisionNote: 'Good'),
    ];
    await _open(tester, h, 'Wash dishes');
    expect(
      routerOf(tester).state.matchedLocation,
      Routes.parentTask('teen1', 't1'),
    );
    expect(find.text('With soap'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Dana'), findsOneWidget);
  });

  testWidgets('cancel asks first; keeping it sends nothing', (tester) async {
    final h = ParentHarness(teens: [_dana]);
    h.tasks.tasks = [fakeTask(id: 't1')];
    await _open(tester, h, 'Wash dishes');

    await tester.tap(find.text('Cancel task'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel this task?'), findsOneWidget);
    expect(h.tasks.decisions, isEmpty);

    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(h.tasks.decisions, isEmpty);
    expect(
      routerOf(tester).state.matchedLocation,
      Routes.parentTask('teen1', 't1'),
    );
  });

  testWidgets('confirming cancels once, goes back and the list is fresh', (
    tester,
  ) async {
    final h = ParentHarness(teens: [_dana]);
    h.tasks.tasks = [fakeTask(id: 't1')];
    await _open(tester, h, 'Wash dishes');
    h.tasks.requests.clear();

    await tester.tap(find.text('Cancel task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, cancel'));
    await tester.pumpAndSettle();

    expect(h.tasks.decisions.map((d) => (d.action, d.id)), [('cancel', 't1')]);
    expect(routerOf(tester).state.matchedLocation, '/parent/home/teen/teen1');
    expect(h.tasks.requests, contains((teenId: 'teen1', state: null)));
    // The open task moved to the finished group on the teen's screen.
    expect(find.text('Wash dishes'), findsNothing);
    expect(find.text('Finished (1)'), findsOneWidget);
  });

  testWidgets('a 409 says the task changed and reloads it', (tester) async {
    final h = ParentHarness(teens: [_dana]);
    h.tasks.tasks = [fakeTask(id: 't1')];
    await _open(tester, h, 'Wash dishes');
    h.tasks.onDecision = (_, _) async {
      h.tasks.tasks = [fakeTask(id: 't1', state: TaskState.approved)];
      throw const ApiException(code: 'invalid_transition', statusCode: 409);
    };

    await tester.tap(find.text('Cancel task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, cancel'));
    await tester.pumpAndSettle();

    expect(
      find.text('This task just changed. Here is the latest.'),
      findsOneWidget,
    );
    expect(
      routerOf(tester).state.matchedLocation,
      Routes.parentTask('teen1', 't1'),
    );
    expect(find.text('Cancel task'), findsNothing, reason: 'now approved');
  });

  group('milestone', () {
    ParentHarness harness({TaskState state = TaskState.assigned}) {
      final h = ParentHarness(teens: [_dana]);
      h.tasks.tasks = [
        fakeTask(
          id: 'm1',
          kind: TaskKind.milestone,
          title: 'School term',
          state: state,
        ),
        fakeTask(
          id: 's1',
          title: 'Step one',
          milestoneId: 'm1',
          state: TaskState.approved,
        ),
        fakeTask(id: 's2', title: 'Step two', milestoneId: 'm1'),
      ];
      return h;
    }

    testWidgets('lists its steps with progress, each opens its task', (
      tester,
    ) async {
      final h = harness();
      await pumpApp(tester, overrides: h.overrides);
      await tester.tap(find.text('Dana'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Milestones (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('School term'));
      await tester.pumpAndSettle();

      expect(find.text('Step one'), findsOneWidget);
      expect(find.text('Step two'), findsOneWidget);
      expect(find.text('1 of 2 done'), findsOneWidget);
      expect(find.text('Cancel milestone'), findsOneWidget);

      await tester.tap(find.text('Step two'));
      await tester.pumpAndSettle();
      expect(
        routerOf(tester).state.matchedLocation,
        Routes.parentTask('teen1', 's2'),
      );
    });

    testWidgets('"Add task to this milestone" opens the form for it', (
      tester,
    ) async {
      final h = harness();
      await pumpApp(tester, overrides: h.overrides);
      await tester.tap(find.text('Dana'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Milestones (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('School term'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add task to this milestone'));
      await tester.pumpAndSettle();
      final uri = routerOf(tester).state.uri;
      expect(uri.path, Routes.parentNew);
      expect(uri.queryParameters['teenId'], 'teen1');
      expect(uri.queryParameters['milestoneId'], 'm1');
      expect(uri.queryParameters.containsKey('kind'), isFalse);
    });

    testWidgets('a submitted milestone can be cancelled but not extended', (
      tester,
    ) async {
      final h = harness(state: TaskState.submitted);
      await pumpApp(tester, overrides: h.overrides);
      await tester.tap(find.text('Dana'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Milestones (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('School term'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel milestone'), findsOneWidget);
      expect(find.text('Add task to this milestone'), findsNothing);
    });
  });
}
