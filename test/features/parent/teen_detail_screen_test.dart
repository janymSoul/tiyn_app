import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';

import '../../helpers/fake_tasks.dart';
import '../../helpers/parent_harness.dart';
import '../../helpers/pump_app.dart';

const _dana = (id: 'teen1', name: 'Dana');
const _aibek = (id: 'teen2', name: 'Aibek');

Future<void> _openDana(WidgetTester tester) async {
  await tester.tap(find.text('Dana'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping a teen opens the detail and keeps the bottom bar', (
    tester,
  ) async {
    final h = ParentHarness(teens: [_dana, _aibek]);
    await pumpApp(tester, overrides: h.overrides);
    await _openDana(tester);

    expect(routerOf(tester).state.matchedLocation, '/parent/home/teen/teen1');
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('My teens'), findsNothing);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Dana')),
      findsOneWidget,
    );
  });

  testWidgets('back returns to the list', (tester) async {
    final h = ParentHarness(teens: [_dana]);
    await pumpApp(tester, overrides: h.overrides);
    await _openDana(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(routerOf(tester).state.matchedLocation, '/parent/home');
    expect(find.text('My teens'), findsOneWidget);
  });

  testWidgets('loads the full history of this teen, once', (tester) async {
    final h = ParentHarness(teens: [_dana]);
    await pumpApp(tester, overrides: h.overrides);
    h.tasks.requests.clear();
    await _openDana(tester);

    expect(h.tasks.requests, [(teenId: 'teen1', state: null)]);
  });

  testWidgets('Tasks tab: open by deadline, milestone children left out', (
    tester,
  ) async {
    final h = ParentHarness(teens: [_dana]);
    h.tasks.tasks = [
      fakeTask(id: '1', title: 'Later', deadlineAt: DateTime.utc(2026, 12, 20)),
      fakeTask(id: '2', title: 'Sooner', deadlineAt: DateTime.utc(2026, 12, 2)),
      fakeTask(
        id: 'm',
        title: 'Term',
        kind: TaskKind.milestone,
        deadlineAt: DateTime.utc(2026, 12, 30),
      ),
      fakeTask(id: 'c', title: 'Step one', milestoneId: 'm'),
    ];
    await pumpApp(tester, overrides: h.overrides);
    await _openDana(tester);

    expect(find.text('Tasks (2)'), findsOneWidget);
    expect(find.text('Milestones (1)'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Sooner')).dy,
      lessThan(tester.getTopLeft(find.text('Later')).dy),
    );
    expect(find.text('Step one'), findsNothing);
    expect(find.text('Term'), findsNothing);
    expect(find.text('To do'), findsNWidgets(2));
    expect(
      find.text(formatMoney(const Money.kzt(150000), locale: 'en')),
      findsNWidgets(2),
    );
  });

  testWidgets('finished tasks sit in a collapsed group', (tester) async {
    final h = ParentHarness(teens: [_dana]);
    h.tasks.tasks = [
      fakeTask(id: '1', title: 'Open one'),
      fakeTask(id: '2', title: 'Done one', state: TaskState.approved),
      fakeTask(id: '3', title: 'Gone one', state: TaskState.cancelled),
    ];
    await pumpApp(tester, overrides: h.overrides);
    await _openDana(tester);

    expect(find.text('Open one'), findsOneWidget);
    expect(find.text('Finished (2)'), findsOneWidget);
    expect(find.text('Done one'), findsNothing);

    await tester.tap(find.text('Finished (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Done one'), findsOneWidget);
    expect(find.text('Gone one'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets('Milestones tab: progress counted from the children', (
    tester,
  ) async {
    final h = ParentHarness(teens: [_dana]);
    h.tasks.tasks = [
      fakeTask(id: 'm', title: 'School term', kind: TaskKind.milestone),
      fakeTask(id: '1', milestoneId: 'm', state: TaskState.approved),
      fakeTask(id: '2', milestoneId: 'm', state: TaskState.approved),
      fakeTask(id: '3', milestoneId: 'm', state: TaskState.submitted),
      fakeTask(id: '4', milestoneId: 'm'),
      fakeTask(id: '5', milestoneId: 'm'),
      fakeTask(id: '6', milestoneId: 'm', state: TaskState.cancelled),
    ];
    await pumpApp(tester, overrides: h.overrides);
    await _openDana(tester);

    await tester.tap(find.text('Milestones (1)'));
    await tester.pumpAndSettle();
    expect(find.text('School term'), findsOneWidget);
    expect(find.text('2 of 5 done'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.4, 1e-9));
  });

  testWidgets('a milestone with no tasks says so', (tester) async {
    final h = ParentHarness(teens: [_dana]);
    h.tasks.tasks = [fakeTask(id: 'm', kind: TaskKind.milestone)];
    await pumpApp(tester, overrides: h.overrides);
    await _openDana(tester);
    await tester.tap(find.text('Milestones (1)'));
    await tester.pumpAndSettle();
    expect(find.text('No tasks yet'), findsOneWidget);
  });

  group('empty tabs', () {
    testWidgets('nothing at all', (tester) async {
      final h = ParentHarness(teens: [_dana]);
      await pumpApp(tester, overrides: h.overrides);
      await _openDana(tester);
      expect(find.text('No tasks yet.'), findsOneWidget);

      await tester.tap(find.text('Milestones (0)'));
      await tester.pumpAndSettle();
      expect(find.text('No milestones yet.'), findsOneWidget);
    });

    testWidgets('only finished work says nothing is open', (tester) async {
      final h = ParentHarness(teens: [_dana]);
      h.tasks.tasks = [fakeTask(state: TaskState.approved)];
      await pumpApp(tester, overrides: h.overrides);
      await _openDana(tester);
      expect(find.text('Nothing open right now.'), findsOneWidget);
      expect(find.text('Finished (1)'), findsOneWidget);
    });
  });

  testWidgets('another teen\'s tasks are not shown', (tester) async {
    final h = ParentHarness(teens: [_dana, _aibek]);
    h.tasks.tasks = [
      fakeTask(id: '1', teenId: 'teen1', title: 'Danas'),
      fakeTask(id: '2', teenId: 'teen2', title: 'Aibeks'),
    ];
    await pumpApp(tester, overrides: h.overrides);
    await _openDana(tester);
    expect(find.text('Danas'), findsOneWidget);
    expect(find.text('Aibeks'), findsNothing);
  });

  testWidgets('a failed load shows an error and retries', (tester) async {
    final h = ParentHarness(teens: [_dana]);
    await pumpApp(tester, overrides: h.overrides);
    h.tasks.error = const ApiException(code: 'network_error');
    await _openDana(tester);
    expect(find.text('No connection. Check your network.'), findsOneWidget);

    h.tasks
      ..error = null
      ..tasks = [fakeTask(title: 'Back again')];
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Back again'), findsOneWidget);
  });

  testWidgets('a failed pull-to-refresh keeps what is on screen', (
    tester,
  ) async {
    final h = ParentHarness(teens: [_dana]);
    h.tasks.tasks = [fakeTask(title: 'Stays')];
    await pumpApp(tester, overrides: h.overrides);
    await _openDana(tester);

    h.tasks.error = const ApiException(code: 'network_error');
    await tester.fling(find.byType(ListView).last, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Stays'), findsOneWidget);
    expect(find.text('No connection. Check your network.'), findsNothing);
  });

  testWidgets('on resume only the visible detail refetches', (tester) async {
    final h = ParentHarness(teens: [_dana]);
    await pumpApp(tester, overrides: h.overrides);
    await _openDana(tester);
    final family = h.family.calls;
    h.tasks.requests.clear();

    h.tasks.tasks = [fakeTask(title: 'Appeared')];
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(h.tasks.callsFor(null), 1, reason: 'this teen, once');
    expect(h.tasks.callsFor(TaskState.submitted), 1);
    expect(h.tasks.callsFor(TaskState.assigned), 1);
    expect(h.family.calls, family, reason: 'the covered home stays quiet');
    expect(find.text('Appeared'), findsOneWidget);
  });
}
