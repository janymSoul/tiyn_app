import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';

import '../../helpers/fake_dashboard.dart';
import '../../helpers/fake_family.dart';
import '../../helpers/pump_app.dart';

class _TeenAuth extends AuthController {
  @override
  Future<User?> build() async =>
      const User(id: 'teen1', role: Role.teen, displayName: 'Dana');
}

class _Harness {
  _Harness([Dashboard? dashboard])
    : dashboard = FakeDashboardRepository(dashboard),
      family = FakeFamilyRepository([
        const FamilyMember(id: 'p1', role: Role.parent, displayName: 'Aigerim'),
      ]);

  final FakeDashboardRepository dashboard;
  final FakeFamilyRepository family;

  List<Override> get overrides => [
    authControllerProvider.overrideWith(_TeenAuth.new),
    familyRepositoryProvider.overrideWithValue(family),
    dashboardRepositoryProvider.overrideWithValue(dashboard),
  ];
}

String _money(int minor) => formatMoney(Money.kzt(minor), locale: 'en');

void main() {
  testWidgets('shows the greeting, available money and the parents', (
    tester,
  ) async {
    final h = _Harness(
      fakeDashboard(
        balance: const Money.kzt(1500000),
        available: const Money.kzt(1250000),
      ),
    );
    await pumpApp(tester, overrides: h.overrides);

    expect(routerOf(tester).state.matchedLocation, '/teen/home');
    expect(find.text('Hi, Dana'), findsOneWidget);
    expect(find.text(_money(1250000)), findsOneWidget, reason: 'available');
    expect(find.text(_money(1500000)), findsNothing, reason: 'not the balance');
    expect(find.text('Connected to Aigerim'), findsOneWidget);
    expect(h.dashboard.calls, 1);
  });

  testWidgets('has no bottom navigation', (tester) async {
    final h = _Harness();
    await pumpApp(tester, overrides: h.overrides);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationDestination), findsNothing);
  });

  group('waiting for check chip', () {
    testWidgets('shows the pending amount', (tester) async {
      final h = _Harness(fakeDashboard(pending: const Money.kzt(150000)));
      await pumpApp(tester, overrides: h.overrides);
      expect(find.text('${_money(150000)} waiting for check'), findsOneWidget);
    });

    testWidgets('is hidden when nothing is pending', (tester) async {
      final h = _Harness(fakeDashboard());
      await pumpApp(tester, overrides: h.overrides);
      expect(find.textContaining('waiting for check'), findsNothing);
      expect(find.byIcon(Icons.hourglass_empty), findsNothing);
    });

    testWidgets('is a chip under the coin, not a sentence', (tester) async {
      final h = _Harness(fakeDashboard(pending: const Money.kzt(150000)));
      await pumpApp(tester, overrides: h.overrides);
      final coin = tester.getRect(find.text(_money(1250000)));
      final chip = tester.getRect(find.byIcon(Icons.hourglass_empty));
      expect(chip.top, greaterThan(coin.bottom));
      expect(find.byType(DecoratedBox), findsWidgets);
    });
  });

  group('work', () {
    testWidgets('lists chores with deadline, reward and state', (tester) async {
      final h = _Harness(
        fakeDashboard(
          chores: [
            fakeChore(id: 'a', title: 'Wash dishes'),
            fakeChore(
              id: 'b',
              title: 'Math homework',
              state: TaskState.submitted,
              reward: const Money.kzt(300000),
            ),
          ],
        ),
      );
      await pumpApp(tester, overrides: h.overrides);

      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Wash dishes'), findsOneWidget);
      expect(find.text('Math homework'), findsOneWidget);
      expect(find.text('To do'), findsOneWidget);
      expect(find.text('Waiting for check'), findsOneWidget);
      expect(find.text(_money(150000)), findsOneWidget);
      expect(find.text(_money(300000)), findsOneWidget);
      expect(find.text('Milestones'), findsNothing);
    });

    testWidgets('groups chores under their milestone', (tester) async {
      final h = _Harness(
        fakeDashboard(
          milestones: [
            fakeMilestone(id: 'm1', approvedTasks: 1, totalTasks: 3),
          ],
          chores: [
            fakeChore(
              id: 'a',
              title: 'Read chapter 1',
              milestoneId: 'm1',
              state: TaskState.approved,
            ),
            fakeChore(id: 'b', title: 'Read chapter 2', milestoneId: 'm1'),
            fakeChore(id: 'c', title: 'Take out trash'),
          ],
        ),
      );
      await pumpApp(tester, overrides: h.overrides);

      expect(find.text('Milestones'), findsOneWidget);
      expect(find.text('School term'), findsOneWidget);
      expect(find.text('1 of 3 done'), findsOneWidget);
      expect(find.text('Read chapter 1'), findsOneWidget);
      expect(find.text('Read chapter 2'), findsOneWidget);

      // Tasks first, then the milestone with its steps inside its card.
      final milestoneTop = tester.getRect(find.text('School term')).top;
      final looseTop = tester.getRect(find.text('Take out trash')).top;
      final stepTop = tester.getRect(find.text('Read chapter 2')).top;
      final chorePosition = tester.getRect(find.text('Tasks')).top;
      expect(chorePosition, lessThan(milestoneTop), reason: 'Tasks first');
      expect(looseTop, lessThan(milestoneTop));
      expect(stepTop, greaterThan(milestoneTop));
    });

    testWidgets('shows chores ungrouped while milestoneId is missing', (
      tester,
    ) async {
      final h = _Harness(
        fakeDashboard(
          milestones: [fakeMilestone(id: 'm1')],
          chores: [
            fakeChore(id: 'a', title: 'Read chapter 1'),
            fakeChore(id: 'b', title: 'Read chapter 2'),
          ],
        ),
      );
      await pumpApp(tester, overrides: h.overrides);

      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Read chapter 1'), findsOneWidget);
      expect(find.text('Read chapter 2'), findsOneWidget);
      expect(find.text('School term'), findsOneWidget);
    });

    testWidgets('a milestone with no steps says so', (tester) async {
      final h = _Harness(fakeDashboard(milestones: [fakeMilestone()]));
      await pumpApp(tester, overrides: h.overrides);
      expect(find.text('No tasks yet'), findsOneWidget);
      expect(find.text('Tasks'), findsNothing);
    });

    testWidgets('nothing to do shows a friendly line, not a blank page', (
      tester,
    ) async {
      final h = _Harness();
      await pumpApp(tester, overrides: h.overrides);
      expect(find.text('Nothing to do right now. Enjoy!'), findsOneWidget);
    });
  });

  group('loading and errors', () {
    testWidgets('a failed load shows a plain message and retries', (
      tester,
    ) async {
      final h = _Harness();
      h.dashboard.error = const ApiException(code: 'network_error');
      await pumpApp(tester, overrides: h.overrides);

      expect(find.text('No connection. Check your network.'), findsOneWidget);
      expect(find.text('Hi, Dana'), findsOneWidget);
      expect(find.text('Nothing to do right now. Enjoy!'), findsNothing);

      h.dashboard
        ..error = null
        ..dashboard = fakeDashboard(chores: [fakeChore(title: 'Back again')]);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Back again'), findsOneWidget);
      expect(find.text('No connection. Check your network.'), findsNothing);
    });

    testWidgets('pull to refresh shows new data', (tester) async {
      final h = _Harness();
      await pumpApp(tester, overrides: h.overrides);
      h.dashboard.dashboard = fakeDashboard(
        chores: [fakeChore(title: 'Fresh')],
      );
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Fresh'), findsOneWidget);
    });

    testWidgets('a failed refresh keeps what is on screen', (tester) async {
      final h = _Harness(fakeDashboard(chores: [fakeChore(title: 'Stays')]));
      await pumpApp(tester, overrides: h.overrides);

      h.dashboard.error = const ApiException(code: 'network_error');
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Stays'), findsOneWidget);
      expect(find.text('No connection. Check your network.'), findsNothing);
    });
  });

  testWidgets('coming back to the app refetches once', (tester) async {
    final h = _Harness();
    await pumpApp(tester, overrides: h.overrides);
    expect(h.dashboard.calls, 1);

    h.dashboard.dashboard = fakeDashboard(pending: const Money.kzt(70000));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(h.dashboard.calls, 1, reason: 'going to the background: no fetch');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(h.dashboard.calls, 2);
    expect(find.text('${_money(70000)} waiting for check'), findsOneWidget);
  });

  testWidgets('sign out is still there', (tester) async {
    final h = _Harness();
    await pumpApp(tester, overrides: h.overrides);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
