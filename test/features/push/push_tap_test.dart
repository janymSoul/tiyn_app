import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiyn_app/app/app.dart';
import 'package:tiyn_app/app/config.dart';
import 'package:tiyn_app/core/push/push_messaging.dart';
import 'package:tiyn_app/core/push/push_providers.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/push/application/device_registration.dart';
import 'package:tiyn_app/features/tasks/application/task_providers.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/features/teen/application/dashboard_controller.dart';

import '../../helpers/fake_dashboard.dart';
import '../../helpers/fake_family.dart';
import '../../helpers/fake_push_backend.dart';
import '../../helpers/fake_push_messaging.dart';
import '../../helpers/fake_tasks.dart';
import '../../helpers/parent_harness.dart';
import '../../helpers/pump_app.dart';

const _parent = User(id: 'parent1', role: Role.parent, displayName: 'Aigerim');
const _teen = User(id: 'teen1', role: Role.teen, displayName: 'Dana');

class _Auth extends AuthController {
  _Auth(this._user, [this._gate]);

  final User? _user;
  final Future<void>? _gate;

  @override
  Future<User?> build() async {
    await _gate;
    return _user;
  }
}

class _Family extends FamilyController {
  _Family(this._load);

  final Future<List<FamilyMember>> Function() _load;

  @override
  Future<List<FamilyMember>> build() => _load();
}

List<Override> _push(FakePushMessaging push) => [
  pushMessagingProvider.overrideWithValue(push),
  pushStoreProvider.overrideWithValue(FakePushStore()),
  deviceRepositoryProvider.overrideWithValue(FakeDeviceRepository()),
];

class _Teen {
  _Teen({List<FamilyMember>? members})
    : family = FakeFamilyRepository(
        members ??
            [
              const FamilyMember(
                id: 'p1',
                role: Role.parent,
                displayName: 'Aigerim',
              ),
            ],
      ),
      tasks = FakeTaskRepository([
        fakeTask(id: 't1', title: 'Wash dishes'),
        fakeTask(id: 'm1', kind: TaskKind.milestone, title: 'School term'),
      ]),
      dashboard = FakeDashboardRepository(
        fakeDashboard(
          chores: [fakeChore(id: 't1')],
          milestones: [
            fakeMilestone(id: 'm1', totalTasks: 2, approvedTasks: 1),
          ],
        ),
      );

  final FakeFamilyRepository family;
  final FakeTaskRepository tasks;
  final FakeDashboardRepository dashboard;

  List<Override> overrides({User user = _teen, Future<void>? authGate}) => [
    authControllerProvider.overrideWith(() => _Auth(user, authGate)),
    familyRepositoryProvider.overrideWithValue(family),
    taskRepositoryProvider.overrideWithValue(tasks),
    dashboardRepositoryProvider.overrideWithValue(dashboard),
  ];
}

PushMessage _tap(String type, [String? taskId]) =>
    PushMessage(data: {'type': type, 'taskId': ?taskId});

String _at(WidgetTester tester) => routerOf(tester).state.matchedLocation;

Future<void> _deliver(
  WidgetTester tester,
  FakePushMessaging push,
  PushMessage m,
) async {
  push.emitOpened(m);
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  group('warm tap (app in the background)', () {
    testWidgets(
      'parent: TASK_SUBMITTED opens that review; back is the To check list',
      (tester) async {
        final push = FakePushMessaging();
        final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
        h.tasks.tasks = [
          fakeTask(
            id: 't9',
            state: TaskState.submitted,
            submittedAt: DateTime.utc(2026, 11, 7),
          ),
        ];
        await pumpApp(tester, overrides: [...h.overrides, ..._push(push)]);
        expect(_at(tester), '/parent/home');

        await _deliver(tester, push, _tap('TASK_SUBMITTED', 't9'));
        expect(_at(tester), '/parent/review/t9');

        routerOf(tester).pop();
        await tester.pumpAndSettle();
        expect(_at(tester), '/parent/review');
      },
    );

    testWidgets('teen: a task push opens the task; back is home', (
      tester,
    ) async {
      final push = FakePushMessaging();
      final h = _Teen();
      await pumpApp(tester, overrides: [...h.overrides(), ..._push(push)]);

      await _deliver(tester, push, _tap('TASK_APPROVED', 't1'));
      expect(_at(tester), '/teen/home/task/t1');

      routerOf(tester).pop();
      await tester.pumpAndSettle();
      expect(_at(tester), '/teen/home');
    });

    testWidgets(
      'teen: a milestone id replaces the task screen with the milestone screen',
      (tester) async {
        final push = FakePushMessaging();
        final h = _Teen();
        await pumpApp(tester, overrides: [...h.overrides(), ..._push(push)]);

        await _deliver(tester, push, _tap('TASK_APPROVED', 'm1'));

        expect(_at(tester), '/teen/home/milestone/m1');
        expect(find.text('School term'), findsWidgets);
        expect(
          find.text('Submit proof'),
          findsNothing,
          reason: 'not shown as a plain task',
        );

        routerOf(tester).pop();
        await tester.pumpAndSettle();
        expect(
          _at(tester),
          '/teen/home',
          reason: 'back skips the replaced screen',
        );
      },
    );

    testWidgets(
      'unknown type, missing id and the wrong role all land on home',
      (tester) async {
        final push = FakePushMessaging();
        final h = _Teen();
        await pumpApp(tester, overrides: [...h.overrides(), ..._push(push)]);

        for (final m in [
          _tap('FROM_THE_FUTURE', 't1'),
          _tap('TASK_APPROVED'),
          _tap('TASK_SUBMITTED', 't1'),
          const PushMessage(),
        ]) {
          await _deliver(tester, push, m);
          expect(_at(tester), '/teen/home');
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets('a teen with no family lands on join whatever was tapped', (
      tester,
    ) async {
      final push = FakePushMessaging();
      final h = _Teen(members: const []);
      await pumpApp(tester, overrides: [...h.overrides(), ..._push(push)]);
      expect(_at(tester), '/teen/join');

      await _deliver(tester, push, _tap('TASK_ASSIGNED', 't1'));
      expect(_at(tester), '/teen/join');
    });
  });

  group('cold start', () {
    testWidgets(
      'the link goes through splash and is applied once auth resolves',
      (tester) async {
        final gate = Completer<void>();
        final push = FakePushMessaging()
          ..initial = _tap('TASK_SUBMITTED', 't9');
        final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
        h.tasks.tasks = [
          fakeTask(
            id: 't9',
            state: TaskState.submitted,
            submittedAt: DateTime.utc(2026, 11, 7),
          ),
        ];
        await _pumpAppNoSettle(tester, [
          ...h.overrides.skip(1), // all but the harness auth
          authControllerProvider.overrideWith(
            () => _Auth(_parent, gate.future),
          ),
          ..._push(push),
        ]);

        expect(_at(tester), '/splash', reason: 'held while auth is unknown');

        gate.complete();
        await tester.pumpAndSettle();

        expect(_at(tester), '/parent/review/t9');
      },
    );

    testWidgets('a teen link waits for the family too', (tester) async {
      final gate = Completer<List<FamilyMember>>();
      final push = FakePushMessaging()..initial = _tap('TASK_ASSIGNED', 't1');
      final h = _Teen();
      await _pumpAppNoSettle(tester, [
        ...h.overrides(),
        familyControllerProvider.overrideWith(() => _Family(() => gate.future)),
        ..._push(push),
      ]);
      await tester.pump();
      expect(_at(tester), '/splash');

      gate.complete(await h.family.members());
      await tester.pumpAndSettle();

      expect(_at(tester), '/teen/home/task/t1');
    });

    testWidgets('a teen link is dropped when the family fails to load', (
      tester,
    ) async {
      final push = FakePushMessaging()..initial = _tap('TASK_ASSIGNED', 't1');
      final h = _Teen();
      var fail = true;
      await _pumpAppNoSettle(tester, [
        ...h.overrides(),
        familyControllerProvider.overrideWith(
          () => _Family(() async {
            if (fail) throw StateError('offline');
            return h.family.members();
          }),
        ),
        ..._push(push),
      ]);
      await tester.pumpAndSettle();

      fail = false;
      await _containerOf(tester)
          .read(familyControllerProvider.notifier)
          .refresh();
      await tester.pumpAndSettle();

      expect(_at(tester), '/teen/home', reason: 'the old tap is not replayed');
    });

    testWidgets(
      'with no session the link is dropped, not kept for the next sign-in',
      (tester) async {
        final push = FakePushMessaging()
          ..initial = _tap('TASK_SUBMITTED', 't9');
        final h = ParentHarness(teens: [(id: 'teen1', name: 'Dana')]);
        h.tasks.tasks = [
          fakeTask(
            id: 't9',
            state: TaskState.submitted,
            submittedAt: DateTime.utc(2026, 11, 7),
          ),
        ];
        await pumpApp(
          tester,
          overrides: [
            ...h.overrides.skip(1),
            authControllerProvider.overrideWith(() => _Auth(null)),
            ..._push(push),
          ],
        );
        expect(_at(tester), '/sign-in');

        final container = _containerOf(tester);
        container.read(authControllerProvider.notifier).signedIn(_parent);
        await tester.pumpAndSettle();

        expect(_at(tester), '/parent/home');
      },
    );

    testWidgets(
      'the link is applied once, not on every auth or family change',
      (tester) async {
        final push = FakePushMessaging()..initial = _tap('TASK_ASSIGNED', 't1');
        final h = _Teen();
        await pumpApp(tester, overrides: [...h.overrides(), ..._push(push)]);
        expect(_at(tester), '/teen/home/task/t1');

        routerOf(tester).go('/teen/home');
        await tester.pumpAndSettle();
        await _containerOf(tester)
            .read(familyControllerProvider.notifier)
            .refresh();
        await tester.pumpAndSettle();

        expect(_at(tester), '/teen/home');
      },
    );
  });
}

ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(TiynApp)));

Future<void> _pumpAppNoSettle(
  WidgetTester tester,
  List<Override> overrides,
) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            flavor: Flavor.staging,
            apiBaseUrl: Uri.parse('https://api.test'),
            googleServerClientId: null,
          ),
        ),
        ...overrides,
      ],
      child: const TiynApp(locale: Locale('en')),
    ),
  );
  await tester.pump();
}
