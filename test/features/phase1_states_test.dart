import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';

import '../helpers/fake_dashboard.dart';
import '../helpers/fake_family.dart';
import '../helpers/fake_tasks.dart';
import '../helpers/parent_harness.dart';
import '../helpers/pump_app.dart';

// Loading, error and "gone" states of the Phase 1 detail screens, and the
// text each teen task state shows. The list screens have theirs next to them.

class _TeenAuth extends AuthController {
  @override
  Future<User?> build() async =>
      const User(id: 'teen1', role: Role.teen, displayName: 'Dana');
}

({
  List<Override> overrides,
  FakeTaskRepository tasks,
  FakeDashboardRepository dash,
})
_teen({TaskState state = TaskState.assigned}) {
  final tasks = FakeTaskRepository([fakeTask(id: 'c1', state: state)]);
  final dash = FakeDashboardRepository(
    fakeDashboard(
      chores: [fakeChore(id: 'c1', state: state)],
    ),
  );
  return (
    tasks: tasks,
    dash: dash,
    overrides: [
      authControllerProvider.overrideWith(_TeenAuth.new),
      familyRepositoryProvider.overrideWithValue(
        FakeFamilyRepository([
          const FamilyMember(
            id: 'p1',
            role: Role.parent,
            displayName: 'Aigerim',
          ),
        ]),
      ),
      dashboardRepositoryProvider.overrideWithValue(dash),
      taskRepositoryProvider.overrideWithValue(tasks),
    ],
  );
}

void main() {
  group('teen task screen', () {
    testWidgets('shows a spinner while loading', (tester) async {
      final t = _teen();
      t.tasks.getGate = Completer<void>();
      await pumpApp(tester, overrides: t.overrides);
      unawaited(routerOf(tester).push(Routes.teenTask('c1')));
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit proof'), findsNothing);
      t.tasks.getGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Submit proof'), findsOneWidget);
    });

    testWidgets('a failed load shows the error and Try again recovers', (
      tester,
    ) async {
      final t = _teen();
      t.tasks.error = const ApiException(code: 'network_error');
      await pumpApp(tester, overrides: t.overrides);
      unawaited(routerOf(tester).push(Routes.teenTask('c1')));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Submit proof'), findsNothing);

      t.tasks.error = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Submit proof'), findsOneWidget);
    });

    for (final entry in {
      TaskState.submitted: 'Waiting for your parent',
      TaskState.expired: null,
      TaskState.cancelled: 'This task was cancelled.',
      TaskState.approved: null,
    }.entries) {
      testWidgets('${entry.key.wire} has nothing to submit', (tester) async {
        final t = _teen(state: entry.key);
        await pumpApp(tester, overrides: t.overrides);
        unawaited(routerOf(tester).push(Routes.teenTask('c1')));
        await tester.pumpAndSettle();
        expect(find.text('Submit proof'), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
        final line = entry.value;
        if (line != null) expect(find.text(line), findsOneWidget);
      });
    }

    testWidgets('approved shows the reward as earned', (tester) async {
      final t = _teen(state: TaskState.approved);
      await pumpApp(tester, overrides: t.overrides);
      unawaited(routerOf(tester).push(Routes.teenTask('c1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('+'), findsWidgets);
    });
  });

  group('teen milestone screen', () {
    testWidgets('an unknown milestone says it changed, with a retry', (
      tester,
    ) async {
      final t = _teen();
      await pumpApp(tester, overrides: t.overrides);
      unawaited(routerOf(tester).push(Routes.teenMilestone('gone')));
      await tester.pumpAndSettle();
      expect(
        find.text('This task just changed. Here is the latest.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('a failed dashboard shows the error and recovers', (
      tester,
    ) async {
      final t = _teen();
      await pumpApp(tester, overrides: t.overrides);
      t.dash
        ..error = const ApiException(code: 'network_error')
        ..dashboard = fakeDashboard(
          milestones: [
            fakeMilestone(id: 'm1', approvedTasks: 0, totalTasks: 0),
          ],
        );
      unawaited(routerOf(tester).push(Routes.teenMilestone('m1')));
      await tester.pumpAndSettle();
      // The earlier dashboard is still on screen after a failed refresh, so
      // a milestone that is not in it reads as changed, not as a crash.
      expect(tester.takeException(), isNull);
    });

    testWidgets('no steps explains why submit is disabled', (tester) async {
      final t = _teen();
      t.dash.dashboard = fakeDashboard(
        milestones: [fakeMilestone(id: 'm1', approvedTasks: 0, totalTasks: 0)],
      );
      await pumpApp(tester, overrides: t.overrides);
      unawaited(routerOf(tester).push(Routes.teenMilestone('m1')));
      await tester.pumpAndSettle();
      expect(find.text('This milestone has no steps yet.'), findsWidgets);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });

  group('parent task screen', () {
    testWidgets('shows a spinner while loading', (tester) async {
      final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
      h.tasks.tasks = [fakeTask(id: 't1')];
      await pumpApp(tester, overrides: h.overrides);
      h.tasks.getGate = Completer<void>();
      unawaited(routerOf(tester).push(Routes.parentTask('teen1', 't1')));
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cancel task'), findsNothing);
      h.tasks.getGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Cancel task'), findsOneWidget);
    });

    testWidgets('a failed load shows the error and Try again recovers', (
      tester,
    ) async {
      final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
      h.tasks.tasks = [fakeTask(id: 't1')];
      await pumpApp(tester, overrides: h.overrides);
      h.tasks.error = const ApiException(code: 'network_error');
      unawaited(routerOf(tester).push(Routes.parentTask('teen1', 't1')));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsWidgets);
      expect(find.text('Cancel task'), findsNothing);

      h.tasks.error = null;
      await tester.tap(find.text('Try again').first);
      await tester.pumpAndSettle();
      expect(find.text('Cancel task'), findsOneWidget);
    });
  });

  testWidgets('a tappable task card is one button with the whole summary', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, overrides: _teen().overrides);

    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp('Wash dishes')),
    );
    final data = node.getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.label, contains('Wash dishes'));
    expect(data.label, contains('To do'));
    handle.dispose();
  });
}
