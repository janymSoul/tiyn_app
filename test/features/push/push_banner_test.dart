import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/money/money.dart';
import 'package:tiyn_app/core/money/money_format.dart';
import 'package:tiyn_app/core/push/push_messaging.dart';
import 'package:tiyn_app/core/push/push_providers.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/push/application/device_registration.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';

import '../../helpers/fake_dashboard.dart';
import '../../helpers/fake_family.dart';
import '../../helpers/fake_push_backend.dart';
import '../../helpers/fake_push_messaging.dart';
import '../../helpers/fake_tasks.dart';
import '../../helpers/parent_harness.dart';
import '../../helpers/pump_app.dart';

class _TeenAuth extends AuthController {
  @override
  Future<User?> build() async =>
      const User(id: 'teen1', role: Role.teen, displayName: 'Dana');
}

class _SignedOut extends AuthController {
  @override
  Future<User?> build() async => null;
}

const _approved = PushMessage(
  title: 'Task approved',
  body: '+1 500 ₸ for Wash dishes',
  data: {'type': 'TASK_APPROVED', 'taskId': 't1'},
);

List<Override> _push(FakePushMessaging push) => [
  pushMessagingProvider.overrideWithValue(push),
  pushStoreProvider.overrideWithValue(FakePushStore()),
  deviceRepositoryProvider.overrideWithValue(FakeDeviceRepository()),
];

class _TeenHarness {
  _TeenHarness()
    : dashboard = FakeDashboardRepository(fakeDashboard()),
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
  testWidgets('shows the title and body of a push that arrives in the app', (
    tester,
  ) async {
    final push = FakePushMessaging();
    final h = _TeenHarness();
    await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);

    push.emitForeground(_approved);
    await tester.pump();
    await tester.pump();

    expect(find.text('Task approved'), findsOneWidget);
    expect(find.text('+1 500 ₸ for Wash dishes'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('a second push replaces the first: never two banners', (
    tester,
  ) async {
    final push = FakePushMessaging();
    final h = _TeenHarness();
    await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);

    push.emitForeground(_approved);
    await tester.pump();
    await tester.pump();
    push.emitForeground(
      const PushMessage(
        title: 'Second',
        body: 'two',
        data: {'type': 'TASK_ASSIGNED'},
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Task approved'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('dismisses itself after a few seconds', (tester) async {
    final push = FakePushMessaging();
    final h = _TeenHarness();
    await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);

    push.emitForeground(_approved);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Task approved'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Task approved'), findsNothing);
  });

  testWidgets('a MediaQuery change does not restart the timer', (tester) async {
    final push = FakePushMessaging();
    final h = _TeenHarness();
    await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);

    push.emitForeground(_approved);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Task approved'), findsNothing);
  });

  testWidgets('a replacing banner restarts the timer', (tester) async {
    final push = FakePushMessaging();
    final h = _TeenHarness();
    await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);

    push.emitForeground(_approved);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    push.emitForeground(
      const PushMessage(title: 'Second', data: {'type': 'TASK_ASSIGNED'}),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Second'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Second'), findsNothing);
  });

  testWidgets('the close button dismisses it', (tester) async {
    final push = FakePushMessaging();
    final h = _TeenHarness();
    await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);

    push.emitForeground(_approved);
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('Task approved'), findsNothing);
  });

  testWidgets('Open goes to the screen for that push', (tester) async {
    final push = FakePushMessaging();
    final h = _TeenHarness();
    await pumpApp(
      tester,
      overrides: [
        ...h.overrides,
        ..._push(push),
        taskRepositoryProvider.overrideWithValue(
          FakeTaskRepository([fakeTask(id: 't1')]),
        ),
      ],
    );

    push.emitForeground(_approved);
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(routerOf(tester).state.matchedLocation, '/teen/home/task/t1');
    expect(find.text('Task approved'), findsNothing);
  });

  testWidgets('no banner and no refresh without a session', (tester) async {
    final push = FakePushMessaging();
    final h = _TeenHarness();
    await pumpApp(
      tester,
      overrides: [
        authControllerProvider.overrideWith(_SignedOut.new),
        dashboardRepositoryProvider.overrideWithValue(h.dashboard),
        ..._push(push),
      ],
    );

    push.emitForeground(_approved);
    await tester.pump();
    await tester.pump();
    expect(find.text('Task approved'), findsNothing);
    expect(h.dashboard.calls, 0);
  });

  testWidgets('a push without text still refreshes but shows no banner', (
    tester,
  ) async {
    final push = FakePushMessaging();
    final h = _TeenHarness();
    await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);
    final before = h.dashboard.calls;

    push.emitForeground(const PushMessage(data: {'type': 'TASK_APPROVED'}));
    await tester.pump();
    await tester.pump();

    expect(find.text('Open'), findsNothing);
    expect(h.dashboard.calls, before + 1);
  });

  testWidgets(
    'teen: an APPROVED push updates the balance with no pull-to-refresh',
    (tester) async {
      final push = FakePushMessaging();
      final h = _TeenHarness();
      await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);
      expect(find.text(_money(1250000)), findsOneWidget);

      h.dashboard.dashboard = fakeDashboard(
        balance: const Money.kzt(1650000),
        available: const Money.kzt(1400000),
      );
      push.emitForeground(_approved);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text(_money(1400000)), findsOneWidget);
      expect(find.text(_money(1250000)), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    },
  );

  testWidgets(
    'a family push refreshes the family without sending the teen to the splash',
    (tester) async {
      final push = FakePushMessaging();
      final h = _TeenHarness();
      await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);
      final before = h.family.calls;

      push.emitForeground(
        const PushMessage(
          title: 'Linked',
          data: {'type': 'FAMILY_LINKED_TEEN'},
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(h.family.calls, before + 1);
      expect(routerOf(tester).state.matchedLocation, '/teen/home');
      await tester.pump(const Duration(seconds: 6));
    },
  );

  testWidgets('parent: a SUBMITTED push refreshes the lists the badge reads', (
    tester,
  ) async {
    final push = FakePushMessaging();
    final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
    await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);
    final submittedBefore = h.tasks.callsFor(TaskState.submitted);
    final assignedBefore = h.tasks.callsFor(TaskState.assigned);

    h.tasks.tasks = [
      fakeTask(
        id: 't9',
        state: TaskState.submitted,
        submittedAt: DateTime.utc(2026, 11, 7),
      ),
    ];
    push.emitForeground(
      const PushMessage(
        title: 'Proof sent',
        body: 'Dana sent proof',
        data: {'type': 'TASK_SUBMITTED', 'taskId': 't9'},
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(h.tasks.callsFor(TaskState.submitted), submittedBefore + 1);
    expect(h.tasks.callsFor(TaskState.assigned), assignedBefore + 1);
    expect(find.text('Proof sent'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets(
    'an unknown type still refreshes the main list and does not throw',
    (tester) async {
      final push = FakePushMessaging();
      final h = _TeenHarness();
      await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);
      final before = h.dashboard.calls;

      push.emitForeground(
        const PushMessage(
          title: 'New',
          body: 'thing',
          data: {'type': 'FROM_THE_FUTURE'},
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(h.dashboard.calls, before + 1);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 6));
    },
  );
}
